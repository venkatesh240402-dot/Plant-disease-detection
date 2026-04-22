class KnowledgeBase {
  static final Map<String, Map<String, String>> _solutions = {
    'tomato': {
      'Healthy': 'Your tomato plant is healthy! Maintain regular watering and sunlight.',
      'Leaf Blight': 'Remove affected leaves, ensure good air circulation, and apply a copper-based fungicide if severe.',
      'Rust': 'Apply a fungicidal spray containing chlorothalonil or sulfur.',
      'Powdery Mildew': 'Improve air circulation, avoid overhead watering, and use neem oil or a sulfur fungicide.',
      'Mosaic Virus': 'There is no cure. Remove and destroy infected plants to prevent spreading. Control aphid populations.',
      'Late Blight': 'Remove infected plants immediately. Apply protective fungicide sprays ahead of wet weather.',
    },
    'apple': {
      'Healthy': 'Your apple tree is in good shape!',
      'Rust': 'Apply protective fungicide starting at blossom time and repeat every 7-10 days.',
      'Powdery Mildew': 'Prune out infected shoots in winter. Use fungicides suited for powdery mildew.',
    },
    // Add default fallbacks for undefined specific maps
  };

  static String getSolution(String crop, String disease) {
    if (disease == 'Healthy') {
      return 'The plant appears healthy. No action required.';
    }

    final cropLower = crop.toLowerCase();
    
    if (_solutions.containsKey(cropLower) && _solutions[cropLower]!.containsKey(disease)) {
      return _solutions[cropLower]![disease]!;
    }
    
    if (disease == 'Unknown Disease') {
      return 'Could not confidently identify the disease. Please attempt scanning again with better lighting and focus on the affected area.';
    }

    // Generic fallbacks
    if (disease.contains('Blight')) {
      return 'Remove affected foliage, ensure proper drainage and avoiding overhead watering. Applying a suitable fungicide is recommended.';
    } else if (disease.contains('Powdery Mildew')) {
      return 'Reduce humidity, improve air flow and consider spraying with neem oil or a sulfur-based fungicide.';
    } else if (disease.contains('Rust')) {
      return 'Isolate infected plants. Apply appropriate anti-fungal treatments and limit excessive moisture.';
    } else if (disease.contains('Virus')) {
      return 'Viral diseases are generally incurable. It is recommended to remove the infected plant to prevent the spread to other crops.';
    }

    return 'Please consult a local agricultural extension office or agronomist for targeted solutions for $disease on $crop.';
  }
}
