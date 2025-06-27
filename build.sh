#!/bin/bash

# Si ya está el SDK en caché, no lo vuelvas a clonar
if [ ! -d "$HOME/flutter" ]; then
  echo "Clonando Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
fi

# Agregar Flutter al PATH
export PATH="$PATH:$HOME/flutter/bin"

# Precargar dependencias
flutter precache
flutter doctor

# Build
flutter build web