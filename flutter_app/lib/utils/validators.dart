class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 8) {
      return 'Senha deve ter pelo menos 8 caracteres';
    }
    return null;
  }

  static String? validateNome(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome é obrigatório';
    }
    if (value.length < 3) {
      return 'Nome deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  static String? validateDataNascimento(String? value) {
    if (value == null || value.isEmpty) {
      return 'Data de nascimento é obrigatória';
    }
    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();
      final idade = now.year - date.year;
      if (idade < 18) {
        return 'Deve ter pelo menos 18 anos';
      }
      if (idade > 120) {
        return 'Data inválida';
      }
      return null;
    } catch (e) {
      return 'Data inválida (use YYYY-MM-DD)';
    }
  }

  static String? validatePeso(String? value) {
    if (value == null || value.isEmpty) {
      return 'Peso é obrigatório';
    }
    try {
      final peso = double.parse(value);
      if (peso < 20 || peso > 300) {
        return 'Peso deve estar entre 20kg e 300kg';
      }
      return null;
    } catch (e) {
      return 'Peso inválido';
    }
  }

  static String? validateAltura(String? value) {
    if (value == null || value.isEmpty) {
      return 'Altura é obrigatória';
    }
    try {
      final altura = int.parse(value);
      if (altura < 100 || altura > 250) {
        return 'Altura deve estar entre 100cm e 250cm';
      }
      return null;
    } catch (e) {
      return 'Altura inválida';
    }
  }

  static String? validateProtein(String? value) {
    if (value == null || value.isEmpty) {
      return 'Proteína é obrigatória';
    }
    try {
      final protein = int.parse(value);
      if (protein < 0 || protein > 500) {
        return 'Proteína deve estar entre 0g e 500g';
      }
      return null;
    } catch (e) {
      return 'Proteína inválida';
    }
  }

  static String? validateWater(String? value) {
    if (value == null || value.isEmpty) {
      return 'Água é obrigatória';
    }
    try {
      final water = int.parse(value);
      if (water < 0 || water > 10000) {
        return 'Água deve estar entre 0ml e 10000ml';
      }
      return null;
    } catch (e) {
      return 'Água inválida';
    }
  }
}
