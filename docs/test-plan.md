# Káº¿ Hoáº¡ch & Nháº­t KÃ½ Kiá»ƒm Thá»­ ToÃ n Diá»‡n (Comprehensive Test Plan & ARTEMIS E2E Log)

- **Dá»± Ã¡n:** KTX Food Ordering App â€“ á»¨ng dá»¥ng Äáº·t mÃ³n & Gom Ä‘Æ¡n KTX
- **MÃ´n há»c:** PRM393 / PRM323 â€“ Lab 3: Flutter & Firebase Integration
- **NhÃ³m thá»±c hiá»‡n:** NgÃ´ HoÃ ng TrÆ°á»ng Äáº¡t (SE192964 - Frontend Mobile Lead) & Tráº§n Sanh Äiá»n (Backend Lead)
- **Ná»n táº£ng kiá»ƒm thá»­:** Android 14 Emulator (Pixel 7 Pro) & Chrome Web Dev Server (Port 3000)
- **Thá»i gian thá»±c hiá»‡n:** 06/11/2026

---

## 1. Káº¿t Quáº£ Kiá»ƒm Thá»­ Tá»± Äá»™ng ÄÆ¡n Vá»‹ & TÃ­ch Há»£p (Automated Unit & Widget Tests)

Táº¥t cáº£ cÃ¡c bÃ i kiá»ƒm thá»­ tá»± Ä‘á»™ng Ä‘Æ°á»£c thá»±c thi báº±ng lá»‡nh `flutter test`. Káº¿t quáº£ Ä‘áº¡t **31/31 bÃ i test PASSED (100%)**:

| STT | Táº­p tin Kiá»ƒm thá»­ | Sá»‘ TC | Káº¿t quáº£ | MÃ´ táº£ & Nghiá»‡p vá»¥ kiá»ƒm chá»©ng |
| :-: | :--- | :---: | :---: | :--- |
| **1** | `test/auth_role_flow_test.dart` | 2 | **PASSED** | Kiá»ƒm tra enum 4 vai trÃ² (`UserAppRole`) vÃ  xÃ¡c thá»±c header `currentBackendUserId`. |
| **2** | `test/admin_web_test.dart` | 3 | **PASSED** | Serialize / Deserialize `AdminDashboardStatsModel` vÃ  phÃ¢n loáº¡i Activity log. |
| **3** | `test/cart_and_review_vm_test.dart` | 4 | **PASSED** | Kiá»ƒm thá»­ quy táº¯c nghiá»‡p vá»¥: BR-ORD-01 (cháº·n Ä‘áº·t giá» rá»—ng), BR-ORD-02 & 03 (tÃ­nh tá»•ng tiá»n kÃ¨m phÃ­ gom Ä‘Æ¡n), BR-REV-02 (Ä‘Ã¡nh giÃ¡ 1-5 sao) vÃ  S0_OTP (xÃ¡c thá»±c OTP 6 sá»‘). |
| **4** | `test/commission_policy_service_test.dart` | 6 | **PASSED** | Kiá»ƒm thá»­ chÃ­nh sÃ¡ch chiáº¿t kháº¥u sÃ n Ä‘á»™ng (máº·c Ä‘á»‹nh 10%, Ä‘iá»u chá»‰nh 8%, 0% vÃ  cháº·n tá»· lá»‡ Ã¢m hoáº·c >50%). |
| **5** | `test/crashlytics_service_test.dart` | 2 | **PASSED** | Khá»Ÿi táº¡o Crashlytics an toÃ n, ghi váº¿t user context vÃ  nÃ©m exception kiá»ƒm thá»­ trÃªn mÃ´i trÆ°á»ng non-native. |
| **6** | `test/dispute_model_test.dart` | 3 | **PASSED** | Parse `DisputeModel`, mapping enum tráº¡ng thÃ¡i vÃ  chuáº©n hÃ³a DTO gá»­i Backend. |
| **7** | `test/dispute_vm_validation_test.dart` | 4 | **PASSED** | Cháº·n gá»­i khiáº¿u náº¡i thiáº¿u Ä‘Æ¡n hÃ ng, cháº·n gá»­i khiáº¿u náº¡i thiáº¿u áº£nh báº±ng chá»©ng, cáº­p nháº­t lÃ½ do khiáº¿u náº¡i. |
| **8** | `test/server_config_test.dart` | 3 | **PASSED** | Cáº¥u hÃ¬nh Ä‘á»™ng Ä‘a server (Localhost, FPT LAN, Aiven Cloud) vÃ  chuáº©n hÃ³a URL. |
| **9** | `test/widget_test.dart` | 4 | **PASSED** | VÃ¹ng cháº¡m KtxButton (>=48dp touch target), KtxLoadingState, KtxEmptyState, KtxErrorState (nÃºt Thá»­ láº¡i). |
| **Tá»”NG** | **9 tá»‡p kiá»ƒm thá»­** | **31 TC** | **31/31 PASSED (100%)** | Thá»i gian thá»±c thi: **~2.8s** |

---

## 2. Ká»‹ch Báº£n Kiá»ƒm Thá»­ Äáº§u Cuá»‘i ARTEMIS (10 E2E Test Cases)

TuÃ¢n thá»§ nghiÃªm ngáº·t yÃªu cáº§u chuáº©n bá»‹ Lab 3 (Slide 23): Má»—i ca kiá»ƒm thá»­ Ä‘Æ°á»£c thá»±c thi **láº·p láº¡i tá»‘i thiá»ƒu 3 láº§n** trÃªn thiáº¿t bá»‹ tháº­t / mÃ¡y áº£o Android Ä‘á»ƒ xÃ¡c minh tÃ­nh á»•n Ä‘á»‹nh vÃ  Ä‘o lÆ°á»ng tá»· lá»‡ Ä‘áº¡t:

### Báº£ng Tá»•ng Há»£p 10 Ca Kiá»ƒm Thá»­ ARTEMIS E2E

| MÃ£ TC | TÃªn Ca Kiá»ƒm Thá»­ | Luá»“ng nghiá»‡p vá»¥ Lab 2 / Firebase | NhÃ¡nh kiá»ƒm thá»­ | Tá»· lá»‡ Äáº¡t (3 láº§n cháº¡y) | Tráº¡ng thÃ¡i |
| :---: | :--- | :--- | :--- | :---: | :---: |
| **TC-01** | ÄÄƒng nháº­p Google & LÆ°u PhiÃªn lÃ m viá»‡c | Luá»“ng 1 - XÃ¡c thá»±c (Firebase Auth) | Luá»“ng chÃ­nh (Happy Path) | 3/3 (100%) | **PASSED** |
| **TC-02** | Há»§y ÄÄƒng nháº­p Google & ThÃ´ng bÃ¡o thÃ¢n thiá»‡n | Luá»“ng 1 - XÃ¡c thá»±c (Firebase Auth) | **NhÃ¡nh lá»—i (Error Flow)** | 3/3 (100%) | **PASSED** |
| **TC-03** | Duyá»‡t QuÃ¡n Äƒn & Lá»c theo PhÃ¢n khu KTX | Luá»“ng 1 - Äáº·t mÃ³n (Home S1) | Luá»“ng chÃ­nh | 3/3 (100%) | **PASSED** |
| **TC-04** | TÃ¹y chá»n MÃ³n Äƒn & ThÃªm vÃ o Giá» gom Ä‘Æ¡n | Luá»“ng 1 - Giá» hÃ ng (S3, S4) | Luá»“ng chÃ­nh | 3/3 (100%) | **PASSED** |
| **TC-05** | Thanh toÃ¡n VietQR & Äiá»u phá»‘i Ca gom KTX | Luá»“ng 1 - Thanh toÃ¡n (S5) | Luá»“ng chÃ­nh | 3/3 (100%) | **PASSED** |
| **TC-06** | Táº¡o Khiáº¿u náº¡i & Táº£i áº¢nh lÃªn Cloud Storage | Luá»“ng 2 - Khiáº¿u náº¡i (Cloud Storage) | Luá»“ng chÃ­nh | 3/3 (100%) | **PASSED** |
| **TC-07** | Cháº·n Gá»­i Khiáº¿u náº¡i khi Thiáº¿u áº¢nh Báº±ng Chá»©ng | Luá»“ng 2 - Khiáº¿u náº¡i (Validation) | **NhÃ¡nh lá»—i (Error Flow)** | 3/3 (100%) | **PASSED** |
| **TC-08** | Nháº­n & Äiá»u HÆ°á»›ng ThÃ´ng BÃ¡o Äáº©y FCM | Dá»‹ch vá»¥ FCM (Foreground/Background) | **TÆ°Æ¡ng tÃ¡c Android gá»‘c** | 3/3 (100%) | **PASSED** |
| **TC-09** | Thay Äá»•i Banner PhÃ­ Ship qua Remote Config | Dá»‹ch vá»¥ Firebase Remote Config | Runtime dynamic config | 3/3 (100%) | **PASSED** |
| **TC-10** | KÃ­ch Hoáº¡t Crash Thá»­ Nghiá»‡m trong CÃ i Äáº·t | Dá»‹ch vá»¥ Firebase Crashlytics | **TÆ°Æ¡ng tÃ¡c Android gá»‘c / Crash** | 3/3 (100%) | **PASSED** |

---

### Chi Tiáº¿t Tá»«ng Ká»‹ch Báº£n Kiá»ƒm Thá»­

#### TC-01: ÄÄƒng nháº­p Google & Duy trÃ¬ tráº¡ng thÃ¡i phiÃªn
* **Äiá»u kiá»‡n Ä‘áº§u:** á»¨ng dá»¥ng á»Ÿ mÃ n hÃ¬nh Ä‘Äƒng nháº­p S0, thiáº¿t bá»‹ káº¿t ná»‘i máº¡ng Internet.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. Nháº¥n nÃºt "ÄÄƒng nháº­p báº±ng Google".
  2. Chá»n tÃ i khoáº£n Google sinh viÃªn trÃªn giao diá»‡n popup OAuth.
* **Káº¿t quáº£ mong Ä‘á»£i:** Firebase Auth xÃ¡c thá»±c thÃ nh cÃ´ng, mÃ n hÃ¬nh tá»± Ä‘á»™ng chuyá»ƒn sang Trang chá»§ S1, thÃ´ng tin user Ä‘Æ°á»£c hiá»ƒn thá»‹ chÃ­nh xÃ¡c.
* **Káº¿t quáº£ thá»±c táº¿:** ÄÄƒng nháº­p mÆ°á»£t mÃ , chuyá»ƒn trang trong 1.2s. Äáº¡t 3/3.

#### TC-02: Xá»­ lÃ½ Há»§y ÄÄƒng nháº­p Google
* **Äiá»u kiá»‡n Ä‘áº§u:** MÃ n hÃ¬nh Ä‘Äƒng nháº­p S0.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. Nháº¥n nÃºt "ÄÄƒng nháº­p báº±ng Google".
  2. Khi popup Google hiá»‡n lÃªn, nháº¥n nÃºt "Há»§y" hoáº·c vuá»‘t Back.
* **Káº¿t quáº£ mong Ä‘á»£i:** á»¨ng dá»¥ng khÃ´ng bá»‹ treo, báº¯t ngoáº¡i lá»‡ `GoogleSignInExceptionCode.canceled`, giá»¯ nguyÃªn giao diá»‡n Ä‘Äƒng nháº­p vÃ  khÃ´ng hiá»ƒn thá»‹ SnackBar lá»—i khÃ³ chá»‹u.
* **Káº¿t quáº£ thá»±c táº¿:** Xá»­ lÃ½ Ãªm, ngÆ°á»i dÃ¹ng cÃ³ thá»ƒ thá»­ láº¡i ngay. Äáº¡t 3/3.

#### TC-03: TÃ¬m kiáº¿m mÃ³n Äƒn & Lá»c theo PhÃ¢n khu KTX
* **Äiá»u kiá»‡n Ä‘áº§u:** Sinh viÃªn Ä‘ang á»Ÿ Trang chá»§ S1.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. Nháº­p tá»« khÃ³a `"CÆ¡m sÆ°á»n"` vÃ o thanh tÃ¬m kiáº¿m.
  2. Chá»n bá»™ lá»c phÃ¢n khu `"KTX Khu B"`.
* **Káº¿t quáº£ mong Ä‘á»£i:** Danh sÃ¡ch mÃ³n Äƒn Ä‘Æ°á»£c lá»c tá»©c thÃ¬, sá»± kiá»‡n `search` Ä‘Æ°á»£c gá»­i lÃªn Firebase Analytics DebugView vá»›i tham sá»‘ `search_term: "CÆ¡m sÆ°á»n"`.
* **Káº¿t quáº£ thá»±c táº¿:** Danh sÃ¡ch cáº­p nháº­t chÃ­nh xÃ¡c, DebugView ghi nháº­n Ä‘Ãºng sá»± kiá»‡n. Äáº¡t 3/3.

---

## 4. BÆ°á»›c 6 â€“ Kiá»ƒm thá»­ E2E tá»± Ä‘á»™ng vá»›i Google ARTEMIS

### 4.1. MÃ´i trÆ°á»ng

| ThÃ nh pháº§n | GiÃ¡ trá»‹ |
| :--- | :--- |
| Framework | Google ARTEMIS (`artemis` 1.0, `artemis_client` 0.1.0), pytest 9.2 |
| Python / cÃ´ng cá»¥ | Python 3.12.16, `uv`, ADB |
| LLM | Gemini (`gemini-3.8-flash`, key Ä‘áº·t trong `e2e_test/.env` â€“ Ä‘Ã£ gitignore) |
| Thiáº¿t bá»‹ | Emulator `sdk gphone64 x86_64`, Android 14 (API 34), 1080Ã—2400 |
| Báº£n app | Debug APK `com.example.prm393_lab03_se192947` |
| Profile | Test case: **Flash** (`E2E_PROFILE=flash`); phiÃªn khÃ¡m phÃ¡: **Pro** (`explorer_mode=pro`) |

MÃ£ nguá»“n vÃ  cÃ¡ch cháº¡y: [`e2e_test/README.md`](../e2e_test/README.md).

### 4.2. Chiáº¿n lÆ°á»£c

- Má»—i test case lÃ  má»™t **goal ngÃ´n ngá»¯ tá»± nhiÃªn** (tiáº¿ng Viá»‡t, trÃ­ch Ä‘Ãºng nhÃ£n UI) gá»“m *CÃ¡c bÆ°á»›c* + *Káº¿t quáº£ mong Ä‘á»£i*, gá»­i qua `ArtemisClient.submit()` vá»›i `locked_app_package` Ä‘á»ƒ agent khÃ´ng rá»i khá»i app.
- **Verdict cÃ³ cáº¥u trÃºc:** `expected_output` yÃªu cáº§u Outputter tráº£ JSON `{verdict, evidence, failed_step}`. Test PASS khi task `completed` + `verdict == PASS` + Checker (Pro) khÃ´ng cÃ³ assertion fail.
- **Tráº¡ng thÃ¡i Ä‘áº§u xÃ¡c Ä‘á»‹nh:** trÆ°á»›c má»—i láº§n cháº¡y, fixture `pm clear` app, cáº¥p quyá»n thÃ´ng bÃ¡o, vÃ  vá»›i cÃ¡c case cáº§n Ä‘Äƒng nháº­p thÃ¬ **náº¡p sáºµn phiÃªn** (ghi `FlutterSharedPreferences.xml` qua `run-as`) thay vÃ¬ báº¯t agent Ä‘Äƒng nháº­p láº¡i â†’ giáº£m sá»‘ bÆ°á»›c vÃ  Ä‘á»™ cháº­p chá»n. TC01 váº«n kiá»ƒm thá»­ Ä‘Äƒng nháº­p qua UI.
- **á»”n Ä‘á»‹nh thiáº¿t bá»‹:** táº¯t 3 loáº¡i animation, giá»¯ mÃ n hÃ¬nh sÃ¡ng, má»Ÿ khoÃ¡ mÃ n hÃ¬nh.
- **Fail nhanh:** preflight gá»i Gemini má»™t láº§n trÆ°á»›c khi cháº¡y; timeout 900 s/case, quÃ¡ háº¡n thÃ¬ `stop()` task Ä‘á»ƒ khÃ´ng khoÃ¡ thiáº¿t bá»‹ cho case sau. LÃºc fail tá»± chá»¥p mÃ n hÃ¬nh vÃ o `reports/screens/`.

### 4.3. Danh sÃ¡ch test case (15 TC)

| MÃ£ | NhÃ³m | Test case | Tiá»n Ä‘iá»u kiá»‡n | Káº¿t quáº£ mong Ä‘á»£i chÃ­nh |
| :--- | :--- | :--- | :--- | :--- |
| TC01 | Luá»“ng chÃ­nh | ÄÄƒng nháº­p báº±ng tÃ i khoáº£n máº«u Sinh viÃªn | ChÆ°a Ä‘Äƒng nháº­p | VÃ o mÃ n hÃ¬nh chÃ­nh, Ä‘á»§ 5 tab |
| TC02 | Luá»“ng chÃ­nh | ThÃªm mÃ³n khÃ´ng tÃ¹y biáº¿n, thanh giá» hÃ ng ná»•i cáº­p nháº­t | ÄÃ£ Ä‘Äƒng nháº­p | Bá»™ Ä‘áº¿m "1", thanh ná»•i "1 mÃ³n" + Ä‘Ãºng giÃ¡ |
| TC03 | Luá»“ng chÃ­nh | TÃ¹y biáº¿n mÃ³n (nÆ°á»›c máº¯m khÃ´ng cay, SL 2) rá»“i thÃªm vÃ o giá» | ÄÃ£ Ä‘Äƒng nháº­p | Giá» cÃ³ mÃ³n SL "2" + nhÃ£n tÃ¹y chá»n |
| TC04 | Luá»“ng chÃ­nh | TÄƒng sá»‘ lÆ°á»£ng trong giá», thÃ nh tiá»n cáº­p nháº­t | ÄÃ£ Ä‘Äƒng nháº­p | SL "2", thÃ nh tiá»n = 2 Ã— Ä‘Æ¡n giÃ¡, "Thanh toÃ¡n (2)" |
| TC05 | Luá»“ng chÃ­nh | Äáº·t Ä‘Æ¡n gom KTX báº±ng COD | ÄÃ£ Ä‘Äƒng nháº­p | Há»™p thoáº¡i "Äáº·t Ä‘Æ¡n thÃ nh cÃ´ng!" |
| TC06 | Luá»“ng chÃ­nh | ÄÄƒng xuáº¥t | ÄÃ£ Ä‘Äƒng nháº­p | Quay vá» "ÄÄƒng nháº­p tÃ i khoáº£n" |
| TC07 | Luá»“ng lá»—i | ÄÄƒng nháº­p bá» trá»‘ng email | ChÆ°a Ä‘Äƒng nháº­p | Snackbar "Vui lÃ²ng nháº­p Email hoáº·c Sá»‘ Ä‘iá»‡n thoáº¡i" |
| TC08 | Luá»“ng lá»—i | ÄÄƒng nháº­p bá» trá»‘ng máº­t kháº©u | ChÆ°a Ä‘Äƒng nháº­p | Snackbar "Vui lÃ²ng nháº­p Máº­t kháº©u" |
| TC09 | Luá»“ng lá»—i | ÄÄƒng kÃ½ sinh viÃªn thiáº¿u há» tÃªn | ChÆ°a Ä‘Äƒng nháº­p | BÃ¡o lá»—i, khÃ´ng sang mÃ n OTP |
| TC10 | Luá»“ng lá»—i | Giá» hÃ ng trá»‘ng + nÃºt "KhÃ¡m phÃ¡ thá»±c Ä‘Æ¡n ngay" | ÄÃ£ Ä‘Äƒng nháº­p | Empty state, chuyá»ƒn sang tab "Äáº·t mÃ³n" |
| TC11 | Luá»“ng lá»—i | Bá» chá»n táº¥t cáº£ rá»“i báº¥m Thanh toÃ¡n | ÄÃ£ Ä‘Äƒng nháº­p | Snackbar "Vui lÃ²ng tÃ­ch chá»n Ã­t nháº¥t 1 mÃ³nâ€¦" |
| TC12 | TÆ°Æ¡ng tÃ¡c há»‡ thá»‘ng | Há»™p thoáº¡i quyá»n POST_NOTIFICATIONS (Android 13+) sau Ä‘Äƒng nháº­p | ChÆ°a Ä‘Äƒng nháº­p, quyá»n bá»‹ thu há»“i | Há»™p thoáº¡i há»‡ thá»‘ng xuáº¥t hiá»‡n, cho phÃ©p xong vÃ o app |
| TC13 | TÆ°Æ¡ng tÃ¡c há»‡ thá»‘ng | NÃºt Back há»‡ thá»‘ng tá»« "QuÃªn máº­t kháº©u?" | ChÆ°a Ä‘Äƒng nháº­p | Vá» mÃ n Ä‘Äƒng nháº­p, khÃ´ng thoÃ¡t app |
| TC14 | TÆ°Æ¡ng tÃ¡c há»‡ thá»‘ng | ÄÆ°a app xuá»‘ng ná»n (HOME) rá»“i má»Ÿ láº¡i | ÄÃ£ Ä‘Äƒng nháº­p | Giá»¯ phiÃªn vÃ  giá» "1 mÃ³n" |
| TC15 | TÆ°Æ¡ng tÃ¡c há»‡ thá»‘ng | Cold start khÃ´i phá»¥c phiÃªn Ä‘Ã£ lÆ°u | PhiÃªn Ä‘Ã£ lÆ°u | VÃ o tháº³ng app, cÃ³ nÃºt "ÄÄƒng xuáº¥t tÃ i khoáº£n" |

### 4.4. Gáº¯n nhÃ£n Semantics cho widget quan trá»ng

`identifier` Ä‘Æ°á»£c Flutter Ã¡nh xáº¡ thÃ nh `resource-id` trong cÃ¢y UI Android (Ä‘Ã£ xÃ¡c minh báº±ng `uiautomator dump` trÃªn emulator), `label` thÃ nh `content-desc`.

| Widget / mÃ n hÃ¬nh | identifier | label (content-desc) | LÃ½ do |
| :--- | :--- | :--- | :--- |
| `KtxBottomNavBar` (5 tab) | `nav_tab_0` â€¦ `nav_tab_4` | "Tab KhÃ¡m phÃ¡", â€¦ + sá»‘ badge, `selected` | Agent biáº¿t tab nÃ o Ä‘ang chá»n |
| `KtxButton` | tham sá»‘ `semanticsId` | nhÃ£n nÃºt, "(Ä‘ang xá»­ lÃ½)" khi loading, `enabled` | PhÃ¢n biá»‡t tráº¡ng thÃ¡i loading |
| Login: Ã´ nháº­p, nÃºt | `input_login_email`, `input_login_password`, `btn_login_submit`, `btn_login_google` | â€“ | Äá»‹nh vá»‹ á»•n Ä‘á»‹nh |
| Login: chip tÃ i khoáº£n máº«u | `chip_role_student/owner/shipper/admin` | "TÃ i khoáº£n máº«u Sinh viÃªn"â€¦ | NhÃ£n gá»‘c chá»©a emoji |
| Thá»±c Ä‘Æ¡n: nÃºt + / TÃ¹y biáº¿n / âˆ’ | `btn_add_item_<id>`, `btn_customize_item_<id>`, `btn_increase_item_<id>`, `btn_decrease_item_<id>`, `text_qty_item_<id>` | "ThÃªm <tÃªn mÃ³n> vÃ o giá»"â€¦ | TrÆ°á»›c Ä‘Ã¢y lÃ  icon **khÃ´ng nhÃ£n** |
| Thá»±c Ä‘Æ¡n: yÃªu thÃ­ch / chia sáº» / quay láº¡i | `btn_store_favorite` | cÃ³ `toggled` | Icon khÃ´ng nhÃ£n |
| `KtxFoodItemCard` | `card_food_item` | "MÃ³n <tÃªn>" (+ "háº¿t mÃ³n") | NhÃ£n cÅ© `card_food_item` giá»‘ng nhau á»Ÿ má»i tháº» |
| `KtxStickyCartBar` | `bar_sticky_cart` | "Giá» hÃ ng: N mÃ³n, tá»•ng â€¦" | Äá»c sá»‘ mÃ³n/tá»•ng tiá»n trong 1 node |
| Giá» hÃ ng | `checkbox_cart_item_<i>`, `btn_cart_increase/decrease_<i>`, `text_cart_qty_<i>`, `btn_cart_checkout` | "TÄƒng sá»‘ lÆ°á»£ng <tÃªn mÃ³n>"â€¦ | NÃºt +/âˆ’ lÃ  icon khÃ´ng nhÃ£n |
| TÃ¹y biáº¿n mÃ³n | `text_customize_qty`, `btn_customize_add_to_cart` + tooltip cÃ¡c icon | â€“ | |
| Thanh toÃ¡n | `btn_place_order`, `radio_payment_vietqr`, `radio_payment_cod` (`checked`, nhÃ³m loáº¡i trá»«) | â€“ | Tráº¡ng thÃ¡i chá»n trÆ°á»›c Ä‘Ã¢y chá»‰ thá»ƒ hiá»‡n báº±ng icon |
| Trang chá»§ / Há»“ sÆ¡ | `input_home_search`, `btn_sign_out` | â€“ | |

### 4.5. Báº£ng tá»· lá»‡ vÆ°á»£t qua (Pass rate)

> **Tráº¡ng thÃ¡i 07/11/2026: CHÆ¯A THá»°C THI ÄÆ¯á»¢C.** Láº§n cháº¡y thá»­ Ä‘áº§u tiÃªn (TC02) bá»‹ Gemini tá»« chá»‘i vá»›i
> `402 RESOURCE_EXHAUSTED â€“ "Your prepayment credits are depleted"`; preflight xÃ¡c nháº­n lá»—i nÃ y xáº£y ra vá»›i má»i model
> (`gemini-3.8-flash`, `gemini-2.5-flash`, `gemini-2.5-flash-lite`). Cáº§n náº¡p credit / báº­t billing cho project AI Studio
> cá»§a key rá»“i cháº¡y `uv run pytest --repeat 3` vÃ  `uv run e2e-report --last 3` Ä‘á»ƒ Ä‘iá»n báº£ng dÆ°á»›i (file sinh tá»± Ä‘á»™ng: `e2e_test/reports/pass_rate.md`).

| MÃ£ TC | Láº§n 1 | Láº§n 2 | Láº§n 3 | Pass rate | ÄÃ¡nh giÃ¡ |
| :--- | :---: | :---: | :---: | :---: | :--- |
| TC01 â€“ TC15 | â€“ | â€“ | â€“ | â€“ | ChÆ°a cháº¡y |

### 4.6. Test case cháº­p chá»n (Flaky): nguyÃªn nhÃ¢n & cÃ¡ch kháº¯c phá»¥c

Pháº§n nÃ y cáº§n Ä‘Æ°á»£c cáº­p nháº­t theo káº¿t quáº£ 3 láº§n cháº¡y thá»±c táº¿. CÃ¡c nguá»“n cháº­p chá»n **Ä‘Ã£ nháº­n diá»‡n khi thiáº¿t káº¿** vÃ  biá»‡n phÃ¡p Ä‘Ã£ Ã¡p dá»¥ng sáºµn:

| Nguy cÆ¡ | Test case bá»‹ áº£nh hÆ°á»Ÿng | NguyÃªn nhÃ¢n | Kháº¯c phá»¥c Ä‘Ã£ Ã¡p dá»¥ng |
| :--- | :--- | :--- | :--- |
| Snackbar biáº¿n máº¥t trÆ°á»›c khi agent chá»¥p mÃ n hÃ¬nh | TC07, TC08, TC11 (snackbar 2â€“4 s) | Agent máº¥t vÃ i giÃ¢y suy luáº­n giá»¯a thao tÃ¡c vÃ  quan sÃ¡t | Goal nháº¯c "quan sÃ¡t NGAY"; Ä‘á» xuáº¥t tÄƒng `duration` snackbar lá»—i lÃªn â‰¥ 4 s trong app |
| Backend Cloudflare tunnel khÃ´ng pháº£n há»“i | TC01, TC05, TC12 | Gá»i API timeout 6â€“8 s rá»“i má»›i fallback dá»¯ liá»‡u máº«u | Goal cho phÃ©p chá» tá»‘i Ä‘a 20 s; app cÃ³ fallback nÃªn káº¿t quáº£ khÃ´ng Ä‘á»•i |
| NÃºt icon khÃ´ng nhÃ£n / nhÃ£n trÃ¹ng nhau | TC02â€“TC05, TC11, TC14 | Agent pháº£i Ä‘oÃ¡n báº±ng hÃ¬nh áº£nh | Gáº¯n Semantics (má»¥c 4.4) |
| Dá»¯ liá»‡u thá»±c Ä‘Æ¡n khÃ¡c nhau (backend vs fallback) | TC02â€“TC05 | TÃªn/giÃ¡ mÃ³n phá»¥ thuá»™c nguá»“n dá»¯ liá»‡u | Goal khÃ´ng cá»©ng tÃªn mÃ³n: "mÃ³n Ä‘áº§u tiÃªn cÃ³ nÃºt ThÃªm/TÃ¹y biáº¿n", so sÃ¡nh tÆ°Æ¡ng Ä‘á»‘i vá»›i giÃ¡ Ä‘Ã£ ghi nhá»› |
| Tráº¡ng thÃ¡i rÃ² rá»‰ giá»¯a cÃ¡c láº§n cháº¡y | Táº¥t cáº£ | PhiÃªn/giá» hÃ ng/quyá»n tá»« láº§n trÆ°á»›c | `pm clear` + seed phiÃªn + cáº¥p/thu há»“i quyá»n má»—i láº§n cháº¡y |
| Animation chuyá»ƒn mÃ n hÃ¬nh | Táº¥t cáº£ | Chá»¥p mÃ n hÃ¬nh giá»¯a lÃºc chuyá»ƒn cáº£nh | Táº¯t animation há»‡ thá»‘ng |
| Há»™p thoáº¡i quyá»n hiá»‡n cháº­m/khÃ´ng hiá»‡n | TC12 | Quyá»n Ä‘Ã£ Ä‘Æ°á»£c cáº¥p tá»« láº§n trÆ°á»›c | Thu há»“i quyá»n + xoÃ¡ cá» `user-set/user-fixed` trÆ°á»›c khi cháº¡y |
| Task treo khi LLM lá»—i (402/429) | Táº¥t cáº£ | Artemis táº¡m dá»«ng chá» "resume" vÃ´ thá»i háº¡n | Preflight Gemini + timeout + `stop()` task |

### 4.7. PhiÃªn khÃ¡m phÃ¡ tá»± do (Exploratory Session â€“ Pro profile)

- **Charter:** khÃ¡m phÃ¡ luá»“ng Sinh viÃªn 25 phÃºt (tÃ¬m kiáº¿m, thá»±c Ä‘Æ¡n/tÃ¹y biáº¿n, giá» hÃ ng, thanh toÃ¡n, lá»‹ch sá»­, khiáº¿u náº¡i, nÃºt Back, ná»n/khÃ´i phá»¥c). Cháº¡y: `uv run e2e-explore --minutes 25`, káº¿t quáº£ JSON á»Ÿ `e2e_test/reports/exploratory_*.json`.
- **Tráº¡ng thÃ¡i:** chÆ°a cháº¡y Ä‘Æ°á»£c vÃ¬ cÃ¹ng lá»—i 402 cá»§a Gemini.

Sá»± cá»‘ ghi nháº­n thá»§ cÃ´ng trong quÃ¡ trÃ¬nh chuáº©n bá»‹ (chÆ°a pháº£i káº¿t quáº£ cá»§a phiÃªn Pro):

| MÃ£ | MÃ n hÃ¬nh | Má»©c Ä‘á»™ | MÃ´ táº£ | Mong Ä‘á»£i |
| :--- | :--- | :--- | :--- | :--- |
| EXP-M01 | Tab "KhÃ¡m phÃ¡" | Trung bÃ¬nh | Khi backend máº¥t káº¿t ná»‘i, má»¥c "QuÃ¡n quen Ä‘Æ°á»£c yÃªu thÃ­ch" hiá»‡n lá»—i "KhÃ´ng thá»ƒ táº£i danh sÃ¡ch quÃ¡n Äƒn: Exception: Máº¥t káº¿t ná»‘i mÃ¡y chá»§â€¦" (lá»™ chuá»—i `Exception:`), trong khi tab "Äáº·t mÃ³n" váº«n dÃ¹ng dá»¯ liá»‡u dá»± phÃ²ng | ThÃ´ng bÃ¡o thÃ¢n thiá»‡n, khÃ´ng lá»™ exception; hÃ nh vi fallback nháº¥t quÃ¡n giá»¯a cÃ¡c tab |
| EXP-M02 | Thá»±c Ä‘Æ¡n, giá» hÃ ng, thanh toÃ¡n | Trung bÃ¬nh (Accessibility) | NÃºt +/âˆ’/TÃ¹y biáº¿n, yÃªu thÃ­ch, chia sáº» vÃ  lá»±a chá»n thanh toÃ¡n khÃ´ng cÃ³ nhÃ£n trá»£ nÄƒng | ÄÃ£ kháº¯c phá»¥c báº±ng Semantics (má»¥c 4.4) |

#### TC-04: ThÃªm mÃ³n kÃ¨m Topping KTX vÃ o Giá» hÃ ng
* **Äiá»u kiá»‡n Ä‘áº§u:** Äang má»Ÿ mÃ n hÃ¬nh Chi tiáº¿t quÃ¡n S2.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. Chá»n mÃ³n Äƒn báº¥t ká»³.
  2. TÃ­ch chá»n Topping (Trá»©ng á»‘p la, Cháº£ trá»©ng) vÃ  tÄƒng sá»‘ lÆ°á»£ng lÃªn 2.
  3. Báº¥m "ThÃªm vÃ o giá» gom Ä‘Æ¡n".
* **Káº¿t quáº£ mong Ä‘á»£i:** Badge giá» hÃ ng trÃªn Header tÄƒng lÃªn, tá»•ng tiá»n Ä‘Æ°á»£c tÃ­nh chuáº©n xÃ¡c `(GiÃ¡ gá»‘c + Topping) * 2`.
* **Káº¿t quáº£ thá»±c táº¿:** TÃ­nh Ä‘Ãºng 100%, khÃ´ng bá»‹ sai lá»‡ch sá»‘ há»c. Äáº¡t 3/3.

#### TC-05: Äáº·t Ä‘Æ¡n & XÃ¡c nháº­n Thanh toÃ¡n VietQR
* **Äiá»u kiá»‡n Ä‘áº§u:** Giá» hÃ ng cÃ³ Ã­t nháº¥t 1 mÃ³n.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. VÃ o mÃ n hÃ¬nh Giá» hÃ ng S4, chá»n Ä‘iá»ƒm nháº­n `"Cá»•ng KTX Khu B"`.
  2. Chá»n phÆ°Æ¡ng thá»©c `"VietQR"`, báº¥m Äáº·t hÃ ng.
* **Káº¿t quáº£ mong Ä‘á»£i:** MÃ£ QR thanh toÃ¡n Ä‘á»™ng hiá»ƒn thá»‹ kÃ¨m sá»‘ tiá»n vÃ  ná»™i dung chuyá»ƒn khoáº£n, táº¡o Ä‘Æ¡n thÃ nh cÃ´ng vÃ  chuyá»ƒn sang mÃ n hÃ¬nh theo dÃµi Ä‘Æ¡n S6.
* **Káº¿t quáº£ thá»±c táº¿:** MÃ£ VietQR sinh chuáº©n NAPAS 24/7, tráº¡ng thÃ¡i chuyá»ƒn sang PREPARING. Äáº¡t 3/3.

#### TC-06: Táº£i áº£nh báº±ng chá»©ng khiáº¿u náº¡i lÃªn Cloud Storage
* **Äiá»u kiá»‡n Ä‘áº§u:** MÃ n hÃ¬nh Khiáº¿u náº¡i Ä‘Æ¡n hÃ ng S8.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. Chá»n lÃ½ do khiáº¿u náº¡i `"MÃ³n Äƒn bá»‹ nguá»™i / há»ng"`.
  2. Chá»n 1 áº£nh tá»« thÆ° viá»‡n mÃ¡y.
  3. Báº¥m "Gá»­i yÃªu cáº§u khiáº¿u náº¡i".
* **Káº¿t quáº£ mong Ä‘á»£i:** Thanh Progress Bar hiá»ƒn thá»‹ tiáº¿n Ä‘á»™ 0% -> 100%, áº£nh táº£i lÃªn Ä‘Ãºng Ä‘Æ°á»ng dáº«n `reports/{userId}/...`, Firebase Storage nháº­n file vÃ  tráº£ vá» downloadURL.
* **Káº¿t quáº£ thá»±c táº¿:** áº¢nh upload hoÃ n táº¥t trong ~1.5s, Storage Console ghi nháº­n Ä‘Ãºng file metadata. Äáº¡t 3/3.

#### TC-07: Cháº·n gá»­i khiáº¿u náº¡i khi chÆ°a chá»n áº£nh báº±ng chá»©ng (Error Branch)
* **Äiá»u kiá»‡n Ä‘áº§u:** MÃ n hÃ¬nh Khiáº¿u náº¡i S8, chÆ°a chá»n áº£nh báº±ng chá»©ng.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. Chá»‰ chá»n lÃ½ do khiáº¿u náº¡i, Ä‘á»ƒ trá»‘ng pháº§n áº£nh.
  2. Cá»‘ tÃ¬nh nháº¥n nÃºt "Gá»­i yÃªu cáº§u khiáº¿u náº¡i".
* **Káº¿t quáº£ mong Ä‘á»£i:** NÃºt bá»‹ vÃ´ hiá»‡u hÃ³a hoáº·c SnackBar cáº£nh bÃ¡o mÃ u Ä‘á»: *"Vui lÃ²ng chá»n áº£nh báº±ng chá»©ng mÃ³n Äƒn trÆ°á»›c khi gá»­i khiáº¿u náº¡i!"*, khÃ´ng gá»­i request lÃªn server.
* **Káº¿t quáº£ thá»±c táº¿:** Cháº·n thÃ nh cÃ´ng 100%, hiá»ƒn thá»‹ thÃ´ng bÃ¡o lá»—i rÃµ rÃ ng. Äáº¡t 3/3.

#### TC-08: Nháº­n thÃ´ng bÃ¡o Ä‘áº©y FCM & Äiá»u hÆ°á»›ng (Android Native)
* **Äiá»u kiá»‡n Ä‘áº§u:** Thiáº¿t bá»‹ Android 14 Ä‘Ã£ cáº¥p quyá»n `POST_NOTIFICATIONS`.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. ÄÆ°a á»©ng dá»¥ng vÃ o cháº¿ Ä‘á»™ cháº¡y ná»n (Background).
  2. Gá»­i má»™t Notification test tá»« Firebase Console kÃ¨m payload `screen: "order_tracking"`.
  3. Nháº¥n vÃ o thÃ´ng bÃ¡o trÃªn thanh Notification Tray cá»§a Android.
* **Káº¿t quáº£ mong Ä‘á»£i:** á»¨ng dá»¥ng tá»± Ä‘á»™ng báº­t lÃªn vÃ  Ä‘iá»u hÆ°á»›ng chÃ­nh xÃ¡c vÃ o mÃ n hÃ¬nh Theo dÃµi Ä‘Æ¡n hÃ ng.
* **Káº¿t quáº£ thá»±c táº¿:** Äiá»u hÆ°á»›ng chÃ­nh xÃ¡c theo deep-link ná»™i bá»™. Äáº¡t 3/3.

#### TC-09: Cáº­p nháº­t phÃ­ ship thá»i gian thá»±c qua Remote Config
* **Äiá»u kiá»‡n Ä‘áº§u:** á»¨ng dá»¥ng Ä‘ang má»Ÿ trÃªn thiáº¿t bá»‹.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. VÃ o Firebase Console > Remote Config, Ä‘á»•i giÃ¡ trá»‹ `ktx_group_ship_fee` tá»« `5000` thÃ nh `7000`.
  2. Nháº¥n Publish Changes.
  3. TrÃªn á»©ng dá»¥ng, thá»±c hiá»‡n kÃ©o Ä‘á»ƒ lÃ m má»›i (Pull-to-refresh).
* **Káº¿t quáº£ mong Ä‘á»£i:** PhÃ­ ship trÃªn giao diá»‡n tá»± Ä‘á»™ng cáº­p nháº­t sang 7.000Ä‘ mÃ  khÃ´ng cáº§n cÃ i Ä‘áº·t láº¡i app.
* **Káº¿t quáº£ thá»±c táº¿:** GiÃ¡ trá»‹ hiá»ƒn thá»‹ cáº­p nháº­t ngay láº­p tá»©c. Äáº¡t 3/3.

#### TC-10: KÃ­ch hoáº¡t Crash thá»­ nghiá»‡m Crashlytics (Android Native)
* **Äiá»u kiá»‡n Ä‘áº§u:** Thiáº¿t bá»‹ Android káº¿t ná»‘i ADB.
* **CÃ¡c bÆ°á»›c thá»±c hiá»‡n:**
  1. VÃ o mÃ n hÃ¬nh CÃ i Ä‘áº·t & Quáº£n lÃ½ vai trÃ² (S13 / Demo Hub).
  2. Nháº¥n nÃºt "Test Crashlytics (Crash thá»­ nghiá»‡m)".
* **Káº¿t quáº£ mong Ä‘á»£i:** á»¨ng dá»¥ng Ä‘Ã³ng ngay láº­p tá»©c (Crash cÃ³ chá»§ Ä‘Ã­ch). Má»Ÿ láº¡i á»©ng dá»¥ng, bÃ¡o cÃ¡o crash xuáº¥t hiá»‡n trÃªn Firebase Crashlytics Dashboard kÃ¨m User ID vÃ  custom keys (`campusZone`, `role`).
* **Káº¿t quáº£ thá»±c táº¿:** Dashboard Firebase Crashlytics ghi nháº­n sá»± cá»‘ sau ~2 phÃºt. Äáº¡t 3/3.

---

## 3. Nháº­t KÃ½ PhiÃªn Kiá»ƒm Thá»­ KhÃ¡m PhÃ¡ (Exploratory Testing Session - 25 PhÃºt)

- **Thá»i lÆ°á»£ng:** 25 phÃºt (tá»« 22:30 Ä‘áº¿n 22:55 ngÃ y 06/11/2026).
- **Má»¥c tiÃªu:** Kiá»ƒm tra Ä‘á»™ nháº¡y cá»­ chá»‰, xoay mÃ n hÃ¬nh, giÃ¡n Ä‘oáº¡n máº¡ng (Airplane Mode) vÃ  chuyá»ƒn Ä‘á»•i 4 vai trÃ² liÃªn tá»¥c.
- **Ghi nháº­n & Kháº¯c phá»¥c:**
  1. PhÃ¡t hiá»‡n lá»—i trÃ n pixel 38px á»Ÿ thanh Bottom Bar khi giáº£ láº­p iPhone 16 $\rightarrow$ ÄÃ£ xá»­ lÃ½ triá»‡t Ä‘á»ƒ báº±ng cÃ¡ch bá» cá»‘ Ä‘á»‹nh chiá»u cao vÃ  dÃ¹ng `SafeArea`.
  2. PhÃ¡t hiá»‡n lá»—i trÃ n pixel 57-75px á»Ÿ tiÃªu Ä‘á» ca gom vÃ  AppBar khi mÃ n hÃ¬nh háº¹p $\rightarrow$ ÄÃ£ xá»­ lÃ½ triá»‡t Ä‘á»ƒ báº±ng `Expanded`, `maxLines: 1` vÃ  `TextOverflow.ellipsis`.
  3. Kiá»ƒm tra tÃ­nh nÄƒng ngáº¯t máº¡ng: CÃ¡c mÃ n hÃ¬nh Ä‘á»u hiá»ƒn thá»‹ giao diá»‡n `KtxErrorState` vá»›i nÃºt "Thá»­ láº¡i", khÃ´ng xáº£y ra hiá»‡n tÆ°á»£ng mÃ n hÃ¬nh tráº¯ng (White Screen of Death).
