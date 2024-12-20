const Map<String, Map<String, List<String>>> uniformItemData = {
  'Shirts': {
    'colors': ['Red', 'Blue', 'White'],
    'sizes': ['18', '20', '22', '24']
  },
  'Dresses': {
    'colors': ['Green', 'White', 'Black'],
    'sizes': ['18', '20', '22', '24']
  },
  'Shorts': {
    'colors': ['Black', 'Blue', 'White'],
    'sizes': ['18', '20', '22', '24']
  },
  'Socks': {
    'colors': ['White', 'Black'],
    'sizes': ['Small', 'Medium', 'Large', 'Extra Large']
  },
};

// Update how `uniformItemColors` and `uniformItemSizes` are extracted
final uniformItemColors = {
  for (var key in uniformItemData.keys) key: uniformItemData[key]!['colors']!
};
final uniformItemSizes = {
  for (var key in uniformItemData.keys) key: uniformItemData[key]!['sizes']!
};
