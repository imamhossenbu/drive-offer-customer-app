// Money helpers.
//
// The backend stores and returns offer prices, order prices and wallet
// transaction amounts as integer **poisha** (1 BDT = 100 poisha). Always convert
// with these helpers instead of guessing the unit from the size of the number
// (the old `p > 1000 ? p / 100 : p` guesses showed e.g. a ৳50 offer as ৳5000).

/// Converts a poisha value from the API (num, numeric string or null) to BDT.
double poishaToBdt(dynamic poisha) {
  if (poisha == null) return 0.0;
  final num p = poisha is num ? poisha : (num.tryParse(poisha.toString()) ?? 0);
  return p / 100.0;
}

/// Formats a BDT amount for display: `50` -> "50", `49.5` -> "49.50".
String formatBdt(num bdt) {
  final rounded = (bdt * 100).round() / 100;
  return rounded == rounded.truncateToDouble()
      ? rounded.toInt().toString()
      : rounded.toStringAsFixed(2);
}
