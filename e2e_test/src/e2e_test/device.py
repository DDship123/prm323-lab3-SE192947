"""ADB helpers that put the emulator and the app into a known state before each test."""

from __future__ import annotations

import base64
import os
import shutil
import subprocess
import time
from dataclasses import dataclass

APP_PACKAGE = os.environ.get("E2E_APP_PACKAGE", "com.example.prm393_lab03_se192947")
APP_ACTIVITY = f"{APP_PACKAGE}/.MainActivity"
NOTIFICATION_PERMISSION = "android.permission.POST_NOTIFICATIONS"

ROLE_STUDENT = "student"


def _adb_binary() -> str:
    found = shutil.which("adb")
    if found:
        return found
    sdk_root = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if sdk_root:
        candidate = os.path.join(sdk_root, "platform-tools", "adb.exe" if os.name == "nt" else "adb")
        if os.path.exists(candidate):
            return candidate
    raise RuntimeError("Không tìm thấy adb. Thêm platform-tools vào PATH hoặc đặt ANDROID_HOME.")


def _shared_prefs_xml(role: str, backend_user_id: int) -> str:
    # Mirrors what AuthGate writes after a successful login (legacy SharedPreferences store).
    return (
        "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>\n"
        "<map>\n"
        '    <boolean name="flutter.is_logged_in" value="true" />\n'
        f'    <string name="flutter.saved_user_role">{role}</string>\n'
        f'    <long name="flutter.saved_backend_user_id" value="{backend_user_id}" />\n'
        "</map>\n"
    )


@dataclass
class Device:
    serial: str

    def adb(self, *args: str, check: bool = True, timeout: float = 60) -> str:
        completed = subprocess.run(
            [_adb_binary(), "-s", self.serial, *args],
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
        )
        if check and completed.returncode != 0:
            raise RuntimeError(
                f"adb {' '.join(args)} thất bại ({completed.returncode}): {completed.stderr.strip()}"
            )
        return completed.stdout.strip()

    def shell(self, command: str, check: bool = True, timeout: float = 60) -> str:
        return self.adb("shell", command, check=check, timeout=timeout)

    def is_app_installed(self) -> bool:
        return f"package:{APP_PACKAGE}" in self.shell(f"pm list packages {APP_PACKAGE}")

    def prepare_for_testing(self) -> None:
        """Disable animations and keep the screen on: both are classic sources of flaky UI steps."""
        for key in ("window_animation_scale", "transition_animation_scale", "animator_duration_scale"):
            self.shell(f"settings put global {key} 0")
        self.shell("svc power stayon true", check=False)
        self.shell("input keyevent KEYCODE_WAKEUP", check=False)
        self.shell("wm dismiss-keyguard", check=False)

    def reset_app(
        self,
        *,
        logged_in_role: str | None = None,
        grant_notifications: bool = True,
    ) -> None:
        """Wipe app data, then optionally seed a saved login session so the test starts past S0."""
        self.shell(f"am force-stop {APP_PACKAGE}")
        self.shell(f"pm clear {APP_PACKAGE}")
        if grant_notifications:
            self.shell(f"pm grant {APP_PACKAGE} {NOTIFICATION_PERMISSION}", check=False)
        else:
            self.shell(f"pm revoke {APP_PACKAGE} {NOTIFICATION_PERMISSION}", check=False)
            self.shell(f"pm clear-permission-flags {APP_PACKAGE} {NOTIFICATION_PERMISSION} user-set user-fixed", check=False)
        if logged_in_role:
            self._seed_session(logged_in_role)

    def _seed_session(self, role: str, backend_user_id: int = 1) -> None:
        payload = base64.b64encode(_shared_prefs_xml(role, backend_user_id).encode("utf-8")).decode("ascii")
        self.shell(
            f"run-as {APP_PACKAGE} sh -c "
            f"'mkdir -p shared_prefs && echo {payload} | base64 -d > shared_prefs/FlutterSharedPreferences.xml'"
        )

    def read_shared_prefs(self) -> str:
        return self.shell(
            f"run-as {APP_PACKAGE} cat shared_prefs/FlutterSharedPreferences.xml", check=False
        )

    def launch_app(self, settle_seconds: float = 6.0) -> None:
        self.shell(f"am start -W -n {APP_ACTIVITY}", timeout=90)
        time.sleep(settle_seconds)

    def stop_app(self) -> None:
        self.shell(f"am force-stop {APP_PACKAGE}", check=False)

    def screenshot(self, destination: str) -> None:
        with open(destination, "wb") as handle:
            completed = subprocess.run(
                [_adb_binary(), "-s", self.serial, "exec-out", "screencap", "-p"],
                stdout=handle,
                stderr=subprocess.PIPE,
                timeout=30,
            )
        if completed.returncode != 0:
            raise RuntimeError(f"Chụp màn hình thất bại: {completed.stderr.decode(errors='replace')}")


def first_connected_serial() -> str:
    output = subprocess.run(
        [_adb_binary(), "devices"], capture_output=True, text=True, timeout=30
    ).stdout
    for line in output.splitlines()[1:]:
        parts = line.split()
        if len(parts) == 2 and parts[1] == "device":
            return parts[0]
    raise RuntimeError("Không có thiết bị/emulator nào ở trạng thái 'device' trong `adb devices`.")
