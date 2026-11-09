from __future__ import annotations

import asyncio
import os
from collections.abc import Callable, Iterator
from pathlib import Path

import pytest
from dotenv import load_dotenv

E2E_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(E2E_ROOT / ".env", override=False)

LLM_PROVIDER = os.environ.get("E2E_LLM_PROVIDER", "gemini").strip().lower()
# Read by Artemis in-process and inherited by the daemon it spawns.
os.environ.setdefault(
    "ARTEMIS_ARTEMIS_JSONC",
    str(E2E_ROOT / ("artemis.openrouter.jsonc" if LLM_PROVIDER == "openrouter" else "artemis.gemini.jsonc")),
)

from artemis_client import ArtemisClient  # noqa: E402

from e2e_test.device import ROLE_STUDENT, Device, first_connected_serial  # noqa: E402
from e2e_test.runner import REPORTS_DIR, ArtemisCaseRunner, CaseOutcome  # noqa: E402

LLM_KEY_NAMES = ("GEMINI_API_KEY", "GOOGLE_API_KEY")


def pytest_addoption(parser: pytest.Parser) -> None:
    parser.addoption(
        "--repeat",
        type=int,
        default=int(os.environ.get("E2E_REPEAT", "1")),
        help="Số lần chạy lại mỗi test case (để đo pass rate / phát hiện flaky).",
    )


def pytest_generate_tests(metafunc: pytest.Metafunc) -> None:
    if "run_index" in metafunc.fixturenames:
        repeat = max(1, metafunc.config.getoption("repeat"))
        metafunc.parametrize(
            "run_index", range(1, repeat + 1), ids=[f"run{i}" for i in range(1, repeat + 1)]
        )


def _preflight_gemini(api_key: str) -> None:
    """Artemis pauses forever on billing errors (402), so fail fast before submitting any task."""
    from google import genai

    model = os.environ.get("E2E_PREFLIGHT_MODEL", "gemini-3.5-flash-lite")
    client = genai.Client(api_key=api_key)
    try:
        client.models.generate_content(model=model, contents="ping")
    except Exception as exc:  # noqa: BLE001 - surface the provider message verbatim
        pytest.exit(f"Gemini API ({model}) không dùng được: {exc}", returncode=2)


def _preflight_openrouter(api_key: str) -> None:
    """Check the key and its remaining credit without spending tokens."""
    import httpx

    try:
        resp = httpx.get(
            "https://openrouter.ai/api/v1/key",
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=20.0,
        )
        resp.raise_for_status()
    except Exception as exc:  # noqa: BLE001 - surface the provider message verbatim
        pytest.exit(f"OpenRouter key không dùng được: {exc}", returncode=2)
    remaining = resp.json().get("data", {}).get("limit_remaining")
    if remaining is not None and remaining <= 0:
        pytest.exit("OpenRouter key đã hết hạn mức (limit_remaining <= 0).", returncode=2)


@pytest.fixture(scope="session")
def device() -> Device:
    if LLM_PROVIDER == "openrouter":
        api_key = os.environ.get("OPEN_ROUTER_API_KEY")
        if not api_key:
            pytest.exit("Thiếu OPEN_ROUTER_API_KEY trong e2e_test/.env.", returncode=2)
        _preflight_openrouter(api_key)
    else:
        api_key = next((os.environ[name] for name in LLM_KEY_NAMES if os.environ.get(name)), None)
        if not api_key:
            pytest.exit(
                "Thiếu GEMINI_API_KEY. Tạo e2e_test/.env từ .env.example hoặc chạy `uv run artemis init`.",
                returncode=2,
            )
        _preflight_gemini(api_key)
    serial = os.environ.get("ANDROID_SERIAL") or first_connected_serial()
    dev = Device(serial)
    if not dev.is_app_installed():
        pytest.exit(
            "App chưa được cài trên thiết bị. Chạy `flutter install` (bản debug) trước.", returncode=2
        )
    dev.prepare_for_testing()
    return dev


@pytest.fixture(scope="session")
def artemis_client(device: Device) -> ArtemisClient:
    from artemis.runtime.daemon_client import ensure_daemon_running

    host = os.environ.get("ARTEMIS_DAEMON_HOST", "127.0.0.1")
    port = int(os.environ.get("ARTEMIS_DAEMON_PORT", "8000"))
    ok, base_url = ensure_daemon_running(host, port, timeout=120.0, wait_ready=True)
    if not ok or not base_url:
        pytest.exit(f"Không khởi động được Artemis daemon tại {host}:{port}.", returncode=2)
    client = ArtemisClient(base_url, device_serial=device.serial, request_timeout=60.0)
    asyncio.run(client.health())
    return client


@pytest.fixture(scope="session")
def case_runner(artemis_client: ArtemisClient, device: Device) -> ArtemisCaseRunner:
    return ArtemisCaseRunner(artemis_client, device.serial)


class AppController:
    def __init__(self, device: Device) -> None:
        self.device = device

    def start_logged_out(self, *, grant_notifications: bool = True) -> None:
        self.device.reset_app(grant_notifications=grant_notifications)
        self.device.launch_app()

    def start_logged_in(self, role: str = ROLE_STUDENT) -> None:
        self.device.reset_app(logged_in_role=role)
        self.device.launch_app()


@pytest.fixture
def app(device: Device) -> Iterator[AppController]:
    controller = AppController(device)
    yield controller
    device.stop_app()


@pytest.fixture
def run_case(
    case_runner: ArtemisCaseRunner, device: Device, request: pytest.FixtureRequest, run_index: int
) -> Callable[..., CaseOutcome]:
    def _run(*, case_id: str, title: str, category: str, goal: str) -> CaseOutcome:
        outcome = case_runner.run_case(
            case_id=case_id, title=title, category=category, goal=goal, run_index=run_index
        )
        if not outcome.passed:
            screens = REPORTS_DIR / "screens"
            screens.mkdir(parents=True, exist_ok=True)
            try:
                device.screenshot(str(screens / f"{case_id}_run{run_index}.png"))
            except Exception:  # noqa: BLE001 - a failed screenshot must not mask the real failure
                pass
        assert outcome.passed, outcome.summary()
        return outcome

    return _run
