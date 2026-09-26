import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../constants.dart';
import 'operator_badge.dart';
import '../../features/offers/offer_detail_sheet.dart';

class OfferCard extends StatelessWidget {
  final DriveOffer? driveOffer;
  final Map<String, dynamic>? rawOffer;
  final bool isDriveOffer;
  final VoidCallback? onTap;

  const OfferCard({
    super.key,
    dynamic offer,
    this.isDriveOffer = true,
    this.onTap,
  })  : driveOffer = offer is DriveOffer ? offer : null,
        rawOffer = offer is Map<String, dynamic> ? offer : null;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isBn = state.isBn;

    String name;
    String operatorStr;
    double regPrice;
    double sellPrice;
    double discount;
    String validity;
    String location;

    if (driveOffer != null) {
      name = driveOffer!.title;
      operatorStr = driveOffer!.operator;
      regPrice = driveOffer!.price;
      sellPrice = driveOffer!.discountPrice > 0 ? driveOffer!.discountPrice : driveOffer!.price;
      discount = (regPrice > sellPrice) ? (regPrice - sellPrice) : driveOffer!.commission;
      validity = driveOffer!.validity;
      location = driveOffer!.location;
    } else {
      final map = rawOffer ?? {};
      name = (map['offerName'] ?? map['name'] ?? map['title'] ?? 'Data Pack').toString();
      operatorStr = (map['operator'] is Map
              ? (map['operator']['name'] ?? map['operator']['code'])
              : (map['operator'] ?? map['operatorName'] ?? 'GP'))
          .toString();

      final regPricePoisha = (map['regularPrice'] ?? map['originalPrice'] ?? map['price'] ?? 0) as num;
      final sellPricePoisha = (map['sellingPrice'] ?? map['discountPrice'] ?? map['price'] ?? 0) as num;

      regPrice = regPricePoisha > 1000 ? regPricePoisha / 100 : regPricePoisha.toDouble();
      sellPrice = sellPricePoisha > 1000 ? sellPricePoisha / 100 : sellPricePoisha.toDouble();
      discount = (regPrice > sellPrice) ? (regPrice - sellPrice) : ((map['cashback'] ?? map['commission'] ?? 0) as num).toDouble();

      validity = (map['validity'] ?? '30 Days').toString();
      location = (map['location'] ?? 'ALL').toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap ??
              () {
                final off = driveOffer ?? (rawOffer != null ? DriveOffer.fromJson(rawOffer!) : null);
                if (off != null) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => OfferDetailSheet(offer: off),
                  );
                }
              },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Operator Logo with Badge
                OperatorBadge(codeOrName: operatorStr, size: 48),
                const SizedBox(width: 14),

                // Offer Info Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),

                      // Tags Row (Validity, Location)
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, size: 11, color: Color(0xFF64748B)),
                                const SizedBox(width: 3),
                                Text(
                                  validity,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (location.isNotEmpty && location != 'ALL')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                location,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Commission / Cashback Badge
                      if (discount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Text(
                            isBn
                                ? '${state.formatCurrency(discount)} সাশ্রয়'
                                : 'Save ${state.formatCurrency(discount)}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Price & Buy Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (regPrice > sellPrice)
                      Text(
                        state.formatCurrency(regPrice),
                        style: const TextStyle(
                          fontSize: 11,
                          decoration: TextDecoration.lineThrough,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    Text(
                      state.formatCurrency(sellPrice),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF15803D), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF15803D).withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        state.t('buy_now'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
