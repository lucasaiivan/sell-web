#!/bin/bash
# Script para migrar transacciones antiguas con creation como int → Timestamp

echo "🔧 Script de Migración de Transacciones"
echo "========================================"
echo ""
echo "⚠️  IMPORTANTE: Este script corregirá transacciones antiguas"
echo "   que tienen el campo 'creation' como integer en lugar de Timestamp"
echo ""
echo "📋 Pasos para ejecutar la migración:"
echo ""
echo "1. Crear archivo migrate_transactions.js con el siguiente contenido:"
echo ""
cat << 'EOF'
// migrate_transactions.js
// Ejecutar en Firebase Console > Firestore o con Firebase Admin SDK

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateTransactions() {
  console.log('🔍 Buscando cuentas...');
  
  const accountsSnapshot = await db.collection('ACCOUNTS').get();
  let totalAccounts = 0;
  let totalTransactions = 0;
  let migratedTransactions = 0;
  
  for (const accountDoc of accountsSnapshot.docs) {
    totalAccounts++;
    const accountId = accountDoc.id;
    console.log(`\n📦 Procesando cuenta: ${accountId}`);
    
    const transactionsSnapshot = await db
      .collection('ACCOUNTS')
      .doc(accountId)
      .collection('TRANSACTIONS')
      .get();
    
    for (const transactionDoc of transactionsSnapshot.docs) {
      totalTransactions++;
      const data = transactionDoc.data();
      
      // Verificar si creation es un número (milliseconds)
      if (typeof data.creation === 'number') {
        console.log(`  🔄 Migrando: ${transactionDoc.id}`);
        
        try {
          // Convertir milliseconds a Timestamp
          const timestamp = admin.firestore.Timestamp.fromMillis(data.creation);
          
          await transactionDoc.ref.update({
            creation: timestamp
          });
          
          migratedTransactions++;
          console.log(`  ✅ Migrado: ${transactionDoc.id}`);
        } catch (error) {
          console.error(`  ❌ Error migrando ${transactionDoc.id}:`, error);
        }
      } else if (data.creation instanceof admin.firestore.Timestamp) {
        console.log(`  ⏭️  Ya es Timestamp: ${transactionDoc.id}`);
      } else {
        console.warn(`  ⚠️  Tipo desconocido para creation en ${transactionDoc.id}:`, typeof data.creation);
      }
    }
  }
  
  console.log('\n\n📊 Resumen de Migración:');
  console.log('========================');
  console.log(`Total de cuentas procesadas: ${totalAccounts}`);
  console.log(`Total de transacciones encontradas: ${totalTransactions}`);
  console.log(`Transacciones migradas: ${migratedTransactions}`);
  console.log(`Transacciones ya correctas: ${totalTransactions - migratedTransactions}`);
  console.log('\n✅ Migración completada!');
}

migrateTransactions()
  .then(() => process.exit(0))
  .catch(error => {
    console.error('❌ Error en migración:', error);
    process.exit(1);
  });
EOF

echo ""
echo "2. Obtener Service Account Key:"
echo "   - Ve a Firebase Console > Project Settings > Service Accounts"
echo "   - Haz clic en 'Generate new private key'"
echo "   - Guarda el archivo como 'serviceAccountKey.json' en la raíz del proyecto"
echo ""
echo "3. Instalar dependencias:"
echo "   npm install firebase-admin"
echo ""
echo "4. Ejecutar el script:"
echo "   node migrate_transactions.js"
echo ""
echo "⚠️  RECOMENDACIONES:"
echo "   - Haz un backup de Firestore antes de ejecutar"
echo "   - Ejecuta primero en un proyecto de prueba"
echo "   - Monitorea la consola durante la ejecución"
echo ""
echo "📌 Alternativamente, puedes ejecutar la migración desde Firebase Console:"
echo "   1. Ve a Firestore > Rules Playground"
echo "   2. Cambia a la pestaña 'Query'"
echo "   3. Usa el código JavaScript proporcionado arriba"
echo ""
