#!/usr/bin/env node

/**
 * Servidor HTTP de prueba para impresora térmica
 * Uso: node server_test.js [puerto]
 */

const express = require('express');
const cors = require('cors');
const app = express();
const port = process.argv[2] || 8080;

// Middleware
app.use(cors());
app.use(express.json());

// Log de requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Estado del servidor
let printerConfig = null;
let isPrinterConfigured = false;

// Endpoints
app.get('/status', (req, res) => {
  res.json({
    status: 'ok',
    message: 'Servidor de impresión activo',
    timestamp: new Date().toISOString(),
    printer: isPrinterConfigured ? 'Configurada' : 'No configurada'
  });
});

app.post('/configure-printer', (req, res) => {
  try {
    const { printerName, config } = req.body;
    
    if (!printerName) {
      return res.status(400).json({
        status: 'error',
        error: 'Nombre de impresora requerido'
      });
    }

    printerConfig = {
      name: printerName,
      config: config || {},
      configuredAt: new Date().toISOString()
    };
    
    isPrinterConfigured = true;
    
    console.log(`✅ Impresora configurada: ${printerName}`);
    console.log('Configuración:', JSON.stringify(config, null, 2));
    
    res.json({
      status: 'ok',
      message: `Impresora '${printerName}' configurada correctamente`
    });
  } catch (error) {
    console.error('Error configurando impresora:', error);
    res.status(500).json({
      status: 'error',
      error: 'Error interno del servidor'
    });
  }
});

app.post('/test-printer', (req, res) => {
  try {
    if (!isPrinterConfigured) {
      return res.status(400).json({
        status: 'error',
        error: 'Impresora no configurada'
      });
    }

    console.log('🧪 TICKET DE PRUEBA');
    console.log('==================');
    console.log('Servidor de Impresión HTTP');
    console.log('Impresora:', printerConfig.name);
    console.log('Fecha:', new Date().toLocaleString());
    console.log('Estado: ✅ Operativo');
    console.log('==================');
    
    res.json({
      status: 'ok',
      message: 'Ticket de prueba enviado a impresora'
    });
  } catch (error) {
    console.error('Error en prueba de impresora:', error);
    res.status(500).json({
      status: 'error',
      error: 'Error al imprimir ticket de prueba'
    });
  }
});

app.post('/print-ticket', (req, res) => {
  try {
    if (!isPrinterConfigured) {
      return res.status(400).json({
        status: 'error',
        error: 'Impresora no configurada'
      });
    }

    const {
      businessName,
      products,
      total,
      paymentMethod,
      customerName,
      cashReceived,
      change,
      timestamp
    } = req.body;

    console.log('🎫 IMPRIMIENDO TICKET');
    console.log('=====================');
    console.log(`Negocio: ${businessName}`);
    console.log(`Cliente: ${customerName || 'Sin nombre'}`);
    console.log(`Fecha: ${new Date(timestamp).toLocaleString()}`);
    console.log('---------------------');
    
    products.forEach((product, index) => {
      console.log(`${index + 1}. ${product.quantity}x ${product.description} - $${product.price}`);
    });
    
    console.log('---------------------');
    console.log(`TOTAL: $${total}`);
    console.log(`Método de pago: ${paymentMethod}`);
    
    if (cashReceived) {
      console.log(`Efectivo recibido: $${cashReceived}`);
      console.log(`Vuelto: $${change || 0}`);
    }
    
    console.log('=====================');
    
    res.json({
      status: 'ok',
      message: 'Ticket impreso correctamente'
    });
  } catch (error) {
    console.error('Error imprimiendo ticket:', error);
    res.status(500).json({
      status: 'error',
      error: 'Error al imprimir ticket'
    });
  }
});

// Manejo de errores
app.use((err, req, res, next) => {
  console.error('Error del servidor:', err);
  res.status(500).json({
    status: 'error',
    error: 'Error interno del servidor'
  });
});

// Manejo de rutas no encontradas
app.use('*', (req, res) => {
  res.status(404).json({
    status: 'error',
    error: 'Endpoint no encontrado'
  });
});

// Iniciar servidor
app.listen(port, '0.0.0.0', () => {
  console.log('🖥️  SERVIDOR HTTP DE IMPRESIÓN TÉRMICA');
  console.log('=====================================');
  console.log(`🌐 Servidor ejecutándose en: http://localhost:${port}`);
  console.log(`🔗 Acceso desde red local: http://0.0.0.0:${port}`);
  console.log('📋 Endpoints disponibles:');
  console.log('   GET  /status           - Estado del servidor');
  console.log('   POST /configure-printer - Configurar impresora');
  console.log('   POST /test-printer     - Prueba de impresión');
  console.log('   POST /print-ticket     - Imprimir ticket');
  console.log('=====================================');
  console.log('✅ Listo para recibir comandos de impresión');
  console.log('');
});

// Manejo de cierre graceful
process.on('SIGINT', () => {
  console.log('\n🛑 Cerrando servidor de impresión...');
  process.exit(0);
});

process.on('SIGTERM', () => {
  console.log('\n🛑 Cerrando servidor de impresión...');
  process.exit(0);
});
