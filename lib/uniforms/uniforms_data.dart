const Map<String, Map<String, List<String>>> uniformItemData = {
  'Shirts': {
    'colors': ['Red', 'Blue', 'White'],
    'sizes': ['18', '20', '22', '24'],
    'prizes': ['400', '450', '500', '550']
  },
  'Dresses': {
    'colors': [
      'Green',
      'White',
      'Black',
      "Red and White Boxes small",
      "Green and White Boxes small",
      "Murema Primary",
      "Checked Green",
      "Checked Red",
      ""
    ],
    'sizes': ['18', '20', '22', '24', '26'],
    'prizes': ['600', '650', '700', '750']
  },
  'Shorts': {
    'colors': [
      'Black',
      'Navy Blue',
      'White',
      'Ciiko',
      'Grey',
      'Ash Grey',
      'Green'
    ],
    'sizes': ['18', '20', '22', '24', '26', '28', '30', '32', '34', '36'],
    'prizes': ['450', '500', '550', '600', '650', '700', '750', '800']
  },
  'Socks': {
    'colors': ['White', 'Black'],
    'sizes': ['Small', 'Medium', 'Large', 'Extra Large'],
    'prizes': ['100', '150', '200']
  },
  'Trousers': {
    'colors': ['Grey', 'Blue', 'Navy Blue', 'Green', 'Black', 'Khaki', 'Brown'],
    'sizes': [
      '20',
      '22',
      '24',
      '26',
      '28',
      '30',
      '32',
      '34',
      '36',
      '38',
      '40',
      '42'
    ],
    'prizes': [
      '500',
      '550',
      '600',
      '650',
      '700',
      '750',
      '800',
      '850',
      '900',
      '950',
      '1000'
    ]
  },
};

// Update how `uniformItemColors` and `uniformItemSizes` are extracted
final uniformItemColors = {
  for (var key in uniformItemData.keys) key: uniformItemData[key]!['colors']!
};
final uniformItemSizes = {
  for (var key in uniformItemData.keys) key: uniformItemData[key]!['sizes']!
};

final uniformItemPrizes = {
  for (var key in uniformItemData.keys) key: uniformItemData[key]!['prizes']!
};
