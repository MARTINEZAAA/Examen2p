# Rick & Morty Explorer

Aplicación Flutter multiplataforma para explorar personajes de la API pública
de Rick and Morty.

## Funcionalidades

- Inicio de sesión y registro de demostración con validación de campos.
- Catálogo con búsqueda por nombre, especie u origen y filtro por estado.
- Vista de detalles del personaje.
- Alta, edición y eliminación local durante la ejecución de la app.
- Carga paginada de personajes desde `https://rickandmortyapi.com/api/character`.
- Mensaje de error y opción para reintentar si falla la conexión.

## Ejecutar

```sh
flutter pub get
flutter run
```

Para ejecutarla en Chrome:

```sh
flutter run -d chrome
```

Credenciales iniciales de demostración: usuario `admin`, contraseña `1234`.
También es posible registrar usuarios desde la pantalla de acceso. Las cuentas
de registro y las operaciones de alta, edición y eliminación se guardan solo en
memoria y se pierden al cerrar la aplicación. La API externa es de consulta:
los cambios locales no modifican su catálogo.

## Organización de `lib`

- `models/character.dart`: modelo `Character` y conversión de JSON.
- `screens/`: acceso, catálogo y detalles/formularios.
- `services/character_api.dart`: consumo paginado de la API usando `Future`,
  `async` y `await`.

Sin conexión, la app informa que no pudo cargar el catálogo y permite reintentar;
no mantiene una caché local para uso offline.

## Validación

```sh
flutter analyze
flutter test
```
