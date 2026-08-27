// FILE: lib/web_live_sync/web_pharoah_numbering_engine.dart

import 'web_models.dart';

class WebPharoahNumberingEngine {
  /// Web sequential gap-filling number generator
  static String getNextNumber({
    required String prefix,
    required int startFrom,
    required List<dynamic> currentList,
  }) {
    List<int> existingNumbers = [];

    for (var item in currentList) {
      String idToParse = "";
      try {
        if (item is Sale) {
          idToParse = item.billNo;
        } else if (item is Purchase) {
          idToParse = item.internalNo;
        } else if (item is SaleChallan) {
          idToParse = item.billNo;
        } else if (item is PurchaseChallan) {
          idToParse = item.internalNo;
        } else if (item is SaleReturn) {
          idToParse = item.billNo;
        } else if (item is PurchaseReturn) {
          idToParse = item.billNo;
        } else if (item is Voucher) {
          idToParse = item.voucherNo;
        } else if (item is Medicine) {
          idToParse = item.systemId;
        } else if (item is Map<String, dynamic>) {
          idToParse = (item['billNo'] ?? item['internalNo'] ?? item['voucherNo'] ?? item['systemId'] ?? '').toString();
        }
      } catch (_) {
        idToParse = "";
      }

      if (idToParse.startsWith(prefix)) {
        String numPart = idToParse.replaceFirst(prefix, "");
        int? n = int.tryParse(numPart);
        if (n != null) existingNumbers.add(n);
      }
    }

    if (existingNumbers.isNotEmpty) {
      existingNumbers.sort();
      for (int i = startFrom; i <= existingNumbers.last; i++) {
        if (!existingNumbers.contains(i)) {
          return "$prefix$i";
        }
      }
      return "$prefix${existingNumbers.last + 1}";
    }

    return "$prefix$startFrom";
  }
}
