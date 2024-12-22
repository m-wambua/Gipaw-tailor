const Map<String, Map<String, List<String>>> uniformItemData = {
  'Shirts': {
    'colors': ['Red', 'Blue', 'White'],
    'sizes': ['18', '20', '22', '24'],
    'prizes':['400','450','500','550']

  },
  'Dresses': {
    'colors': ['Green', 'White', 'Black'],
    'sizes': ['18', '20', '22', '24'],
    'prizes':['600','650','700','750']
  },
  'Shorts': {
    'colors': ['Black', 'Blue', 'White'],
    'sizes': ['18', '20', '22', '24'],
    'prizes':['500','550','600','650']
  },
  'Socks': {
    'colors': ['White', 'Black'],
    'sizes': ['Small', 'Medium', 'Large', 'Extra Large'],
    'prizes':['100','150','200']
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