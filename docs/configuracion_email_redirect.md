# Configuración de Email Redirect URL en Supabase

## Problema
El email de confirmación redirige a `localhost:3000` en lugar de la app móvil.

## Solución 1: Desactivar Confirmación de Email (Desarrollo)

1. Ve a Supabase Dashboard
2. **Authentication** → **Settings**
3. Desactiva **"Enable email confirmations"**
4. Guarda cambios

## Solución 2: Configurar Deep Link (Producción)

### Paso 1: Configurar en Supabase Dashboard

1. Ve a **Authentication** → **URL Configuration**
2. En **Redirect URLs**, agrega:
   ```
   haku://auth-callback
   ```
3. Guarda cambios

### Paso 2: Configurar Deep Link en Flutter

#### Android (`android/app/src/main/AndroidManifest.xml`)

Agrega dentro de `<activity android:name=".MainActivity">`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="haku"
        android:host="auth-callback" />
</intent-filter>
```

#### iOS (`ios/Runner/Info.plist`)

Agrega antes de `</dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>haku</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>haku</string>
        </array>
    </dict>
</array>
```

### Paso 3: Actualizar Código de Registro

En `autenticacion_repositorio_supabase.dart`, actualiza el método de registro:

```dart
@override
Future<Usuario> registrarUsuario(String nombre, String email, String password, String dni) async {
  // 1. Crear usuario en Supabase Auth con redirect
  final AuthResponse res = await _supabase.auth.signUp(
    email: email,
    password: password,
    emailRedirectTo: 'haku://auth-callback', // ← AGREGAR ESTO
  );

  if (res.user == null) throw Exception('Error al registrarse');

  // ... resto del código
}
```

### Paso 4: Manejar el Callback

Agrega en `main.dart`:

```dart
import 'package:app_links/app_links.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
  
  // Manejar deep links
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    // Supabase maneja automáticamente el token
    print('Deep link recibido: $uri');
  });
  
  setupLocator();
  runApp(
    MultiProvider(
      providers: [...],
      child: const MyApp(),
    ),
  );
}
```

Agrega la dependencia en `pubspec.yaml`:

```yaml
dependencies:
  app_links: ^6.4.1
```

## Solución 3: Usar Email Magic Link (Más Simple)

En lugar de password, usa magic links:

```dart
await _supabase.auth.signInWithOtp(
  email: email,
  emailRedirectTo: 'haku://auth-callback',
);
```

## Recomendación

Para **desarrollo rápido**: Usa **Solución 1** (desactivar confirmación)
Para **producción**: Usa **Solución 2** (deep links)
