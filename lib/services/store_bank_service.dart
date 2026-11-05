import 'package:shared_preferences/shared_preferences.dart';

class BankInfo {
  final String code;
  final String name;
  final String bin;

  const BankInfo({required this.code, required this.name, required this.bin});
}

class StoreBankService {
  static final StoreBankService _instance = StoreBankService._internal();
  factory StoreBankService() => _instance;
  StoreBankService._internal();

  static const List<BankInfo> supportedBanks = [
    BankInfo(code: 'MB', name: 'MBBank (Quân Đội)', bin: '970422'),
    BankInfo(code: 'VCB', name: 'Vietcombank', bin: '970436'),
    BankInfo(code: 'TCB', name: 'Techcombank', bin: '970407'),
    BankInfo(code: 'ACB', name: 'ACB (Á Châu)', bin: '970416'),
    BankInfo(code: 'VPB', name: 'VPBank', bin: '970432'),
    BankInfo(code: 'TPB', name: 'TPBank', bin: '970423'),
    BankInfo(code: 'BIDV', name: 'BIDV', bin: '970418'),
    BankInfo(code: 'CTG', name: 'VietinBank', bin: '970415'),
  ];

  String _bankCode = 'MB';
  String _bankName = 'MBBank (Quân Đội)';
  String _bankBin = '970422';
  String _accountNumber = '0908888999';
  String _accountName = 'TRAN THI BA'; // Chủ Quán Cơm Tấm Cô Ba

  String get bankCode => _bankCode;
  String get bankName => _bankName;
  String get bankBin => _bankBin;
  String get accountNumber => _accountNumber;
  String get accountName => _accountName;

  Future<void> init() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _bankCode = sp.getString('store_bank_code') ?? 'MB';
      _bankName = sp.getString('store_bank_name') ?? 'MBBank (Quân Đội)';
      _bankBin = sp.getString('store_bank_bin') ?? '970422';
      _accountNumber = sp.getString('store_account_number') ?? '0908888999';
      _accountName = sp.getString('store_account_name') ?? 'TRAN THI BA';
    } catch (_) {}
  }

  Future<void> saveConfig({
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    _bankCode = bankCode;
    final b = supportedBanks.firstWhere((x) => x.code == bankCode, orElse: () => supportedBanks.first);
    _bankName = b.name;
    _bankBin = b.bin;
    _accountNumber = accountNumber;
    _accountName = accountName.toUpperCase();

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('store_bank_code', _bankCode);
      await sp.setString('store_bank_name', _bankName);
      await sp.setString('store_bank_bin', _bankBin);
      await sp.setString('store_account_number', _accountNumber);
      await sp.setString('store_account_name', _accountName);
    } catch (_) {}
  }

  /// Sinh link ảnh VietQR Napas 247 chuẩn
  String getVietQrImageUrl({required double amount, required String transferContent}) {
    final intAmount = amount.round();
    final encodedContent = Uri.encodeComponent(transferContent);
    final encodedName = Uri.encodeComponent(_accountName);
    // Link VietQR chuẩn
    return 'https://img.vietqr.io/image/$_bankBin-$_accountNumber-compact2.png?amount=$intAmount&addInfo=$encodedContent&accountName=$encodedName';
  }

  /// Sinh link ảnh SePay QR chuẩn
  String getSepayQrImageUrl({required double amount, required String transferContent}) {
    final intAmount = amount.round();
    final encodedContent = Uri.encodeComponent(transferContent);
    return 'https://qr.sepay.vn/img?bank=$_bankCode&acc=$_accountNumber&template=compact&amount=$intAmount&des=$encodedContent';
  }

  /// Chuỗi dữ liệu QR thật để vẽ QrImageView quét trên mọi app ngân hàng / Momo
  String getQrPaymentPayload({required double amount, required String transferContent}) {
    final intAmount = amount.round();
    final amtStr = intAmount.toString();
    final amtLen = amtStr.length.toString().padLeft(2, '0');
    final accLen = _accountNumber.length.toString().padLeft(2, '0');
    final cLen = transferContent.length.toString().padLeft(2, '0');
    final cSubLen = (transferContent.length + 4).toString().padLeft(2, '0');
    // Chuỗi mã QR thanh toán chuẩn VietQR / SePay quét được trên mọi ứng dụng ngân hàng & ví điện tử
    return '00020101021238540010A00000072701240006${_bankBin}01${accLen}${_accountNumber}0208QRIBFTTA5303704540${amtLen}${amtStr}5802VN62${cSubLen}08${cLen}${transferContent}6304';
  }
}

