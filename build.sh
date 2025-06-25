#!/bin/bash

# Descarga Flutter si no existe
if [ ! -d "flutter" ]; then
  echo "Clonando Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable
fi

# Agrega flutter al PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Asegura que se descargue el entorno necesario
flutter precache
flutter doctor

# Compila el proyecto Flutter Web
flutter build web
