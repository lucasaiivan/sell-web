# Firestore Database Structure

## ⚠️ IMPORTANTE - ÚNICA FUENTE DE VERDAD

**SIEMPRE** usar la clase `FirestorePaths` ubicada en:
```
lib/core/services/database/firestore_paths.dart
```

**NUNCA** uses strings hardcoded para rutas de Firestore.

## Uso Correcto

```dart
// ✅ CORRECTO
import 'package:sellweb/core/services/database/firestore_paths.dart';

final ref = firestore.collection(FirestorePaths.accounts);
final docRef = firestore.doc(FirestorePaths.account(accountId));
final catalogueRef = firestore.collection(FirestorePaths.accountCatalogue(accountId));
```

```dart
// ❌ INCORRECTO - NUNCA hacer esto
final ref = firestore.collection('bussines');
final ref = firestore.collection('ACCOUNTS');
```

## Estructura Principal de Base de Datos

### Colecciones Raíz
| Path | Descripción |
|------|-------------|
| `/ACCOUNTS` | Cuentas de negocios/comercios |
| `/USERS` | Usuarios del sistema (indexados por email) |
| `/APP` | Datos públicos de la aplicación |

### Sub-colecciones de ACCOUNTS (`/ACCOUNTS/{accountId}/...`)
| Path | Descripción |
|------|-------------|
| `CATALOGUE` | Productos del catálogo |
| `CATEGORY` | Categorías de productos |
| `PROVIDER` | Proveedores |
| `TRANSACTIONS` | Ventas/transacciones |
| `USERS` | Administradores de la cuenta |
| `CASHREGISTERS` | Cajas registradoras activas |
| `RECORDS` | Historial de arqueos de caja |
| `SETTINGS` | Configuraciones de la cuenta |
| `FIXERDESCRIPTIONS` | Descripciones fijas |

### Sub-colecciones de USERS (`/USERS/{email}/...`)
| Path | Descripción |
|------|-------------|
| `ACCOUNTS` | Cuentas administradas por el usuario |

### Colecciones de APP (`/APP/{country}/...`)
| Path | Descripción |
|------|-------------|
| `PRODUCTOS` | Productos públicos |
| `BRANDS` | Marcas registradas |
| `PRODUCTS_PENDING` | Productos pendientes de moderación |
| `REPORTS` | Reportes de productos |

## Métodos Disponibles en FirestorePaths

```dart
// Cuentas
FirestorePaths.accounts                    // '/ACCOUNTS'
FirestorePaths.account(accountId)          // '/ACCOUNTS/{accountId}'

// Sub-colecciones de cuenta
FirestorePaths.accountCatalogue(accountId)
FirestorePaths.accountProduct(accountId, productId)
FirestorePaths.accountCategories(accountId)
FirestorePaths.accountProviders(accountId)
FirestorePaths.accountTransactions(accountId)
FirestorePaths.accountTransaction(accountId, transactionId)
FirestorePaths.accountUsers(accountId)
FirestorePaths.accountUser(accountId, email)
FirestorePaths.accountCashRegisters(accountId)
FirestorePaths.accountCashRegister(accountId, cashRegisterId)
FirestorePaths.accountCashRegisterHistory(accountId)
FirestorePaths.accountSettings(accountId)
FirestorePaths.analyticsPreferences(accountId)

// Usuarios
FirestorePaths.users                       // '/USERS'
FirestorePaths.user(email)                 // '/USERS/{email}'
FirestorePaths.userManagedAccounts(email)
FirestorePaths.userManagedAccount(email, accountId)

// Datos públicos
FirestorePaths.publicProducts(country: 'ARG')
FirestorePaths.brands(country: 'ARG')
FirestorePaths.productPrices(productId: id, country: 'ARG')
```
