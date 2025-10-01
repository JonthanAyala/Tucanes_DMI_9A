# 📱 Proyecto Integrador · App de Gestión de Paquetería

## 🎯 Objetivo

Desarrollar una **aplicación móvil profesional** en Flutter, aplicando MVVM, metodologías ágiles y tecnologías modernas. El proyecto debe reflejar todos los conceptos de la Unidad I, cumpliendo los requerimientos y lineamientos obligatorios.

---

## 🏗️ Arquitectura y Estructura de Carpetas MVVM

La app utiliza el patrón **MVVM (Model-View-ViewModel)** para mantener el código organizado, escalable y fácil de mantener. Cada carpeta cumple una función específica dentro de la arquitectura:

### 📂 Estructura Base

```
/lib
  /models        # Modelos de datos y entidades (ej. Paquete, Usuario)
  /services      # Lógica de negocio y acceso a APIs, Firebase, almacenamiento
  /utils         # Funciones auxiliares, helpers, constantes, validaciones
  /views         # Pantallas y widgets principales (UI)
  /viewmodels    # Lógica de presentación, gestión de estado y conexión entre modelos y vistas
  /widgets       # Componentes reutilizables (botones, cards, formularios, etc.)
```

### 🧩 Explicación de Carpetas

- **models/**  
  Define las clases que representan los datos principales de la app (por ejemplo, `Paquete`, `Usuario`). Incluye métodos para serialización/deserialización y validaciones básicas.

- **services/**  
  Contiene la lógica para interactuar con fuentes externas: APIs REST, Firebase, almacenamiento local, notificaciones, etc. Aquí se centralizan las operaciones de negocio y comunicación.

- **utils/**  
  Incluye utilidades generales como validadores, formateadores, constantes globales, manejo de fechas, helpers y funciones que pueden ser usadas en cualquier parte del proyecto.

- **views/**  
  Agrupa las pantallas principales de la app (ejemplo: Login, Registro, Lista de Paquetes, Mapa, Perfil). Cada vista se enfoca en la presentación y recibe datos desde su ViewModel.

- **viewmodels/**  
  Aquí vive la lógica de presentación y gestión de estado. Los ViewModels conectan los modelos y servicios con las vistas, procesando datos y notificando cambios a la UI.

- **widgets/**  
  Componentes visuales reutilizables como botones personalizados, cards, formularios, listas, iconos, etc. Permiten construir la UI de forma modular y consistente.

---

**Ejemplo de flujo MVVM:**

1. **View** solicita datos al **ViewModel**.
2. **ViewModel** usa un **Service** para obtener o modificar datos en el **Model**.
3. **ViewModel** procesa la información y actualiza el estado.
4. **View** se actualiza automáticamente al recibir cambios del **ViewModel**.
5. **Widgets** se usan dentro de las **Views** para construir la interfaz de usuario.

Esta estructura facilita el mantenimiento, las pruebas y la escalabilidad del proyecto, asegurando una clara separación de responsabilidades.

---

## ☁️ Backend y Servicios en la Nube

- **Backend:** Firebase (autenticación, base de datos, storage, notificaciones)
- **Consumo de APIs:** Dio configurado (headers, interceptors, manejo de errores)
- **No se utiliza localhost:** Todo en la nube

---

## 🔐 Autenticación de Usuarios

- **Pantalla de Login** con validaciones y gestión de sesión
- **Pantalla de Registro** con selección de rol y confirmación
- **Persistencia de sesión:** SharedPreferences
- **Logout funcional**

---

# 📦 Aplicación de Reparto de Paquetes

## Descripción General

Aplicación móvil diseñada para empresas de mensajería o logística, donde repartidores, clientes y administradores pueden gestionar envíos de paquetes en tiempo real. Permite registrar paquetes, asignar repartidores, rastrear entregas y enviar notificaciones automáticas.

---

## Funcionalidades Principales

### 1. **Autenticación de usuarios**
- **Login y registro** para repartidores, clientes y administradores.
- **Roles con permisos diferenciados:** CRUD limitado según rol.
- **Persistencia de sesión:** SharedPreferences y tokens JWT.

### 2. **Gestión de paquetes (CRUD completo)**
- **Crear paquete:** Registro con datos de destinatario, dirección, peso y fotos.
- **Editar paquete:** Actualización de estado, dirección o detalles.
- **Eliminar paquete:** Solo administradores, con confirmación.
- **Ver detalles:** Historial de estados (pendiente, en tránsito, entregado).
- **Lista de paquetes:** Filtrado por estado, destinatario o repartidor.

### 3. **Cámara y escaneo**
- **Tomar foto** al registrar o entregar paquete.
- **Escaneo de códigos QR** para confirmar entregas.

### 4. **Geolocalización**
- **Ubicación actual del repartidor** en mapa.
- **Check-in automático** al llegar al destino.

### 5. **Notificaciones push**
- **Alertas para clientes:** En camino, entregado, retraso.
- **Alertas para repartidores:** Nueva asignación, cambios de ruta.
- **Gestión con Firebase Cloud Messaging**.

### 6. **Persistencia de datos**
- **SQLite** para historial local.
- **Sincronización automática** con backend (Firebase/AWS).
- **Cache para offline:** Operación sin internet y sincronización posterior.

### 7. **UI profesional**
- **Navegación:** BottomNavigationBar (Paquetes, Mapa, Perfil, Historial).
- **Animaciones sutiles** para actualizaciones.
- **Estados de carga y error:** CircularProgressIndicator y SnackBars.

### 8. **Backend en la nube**
- **APIs RESTful o GraphQL** con JWT y control de roles.
- **Manejo de errores:** Interceptores y retry logic (Dio).
- **Base de datos escalable:** Firebase Firestore o MySQL/PostgreSQL en AWS.

---

## Extras Opcionales (Menor Prioridad)

- **Dashboard de administrador:** Métricas (entregados, en tránsito, retrasos).
- **Exportación de historial:** PDF/Excel.
- **Ruta optimizada del repartidor:** Google Maps Directions API.
- **Chat en tiempo real** entre repartidor y cliente.

---

## Esquema de Roles y Permisos

| Funcionalidad           | Cliente | Repartidor | Administrador |
|------------------------|:-------:|:----------:|:-------------:|
| Registrar paquete      |   ✔️    |            |      ✔️      |
| Editar paquete         |   ✔️*   |    ✔️*     |      ✔️      |
| Eliminar paquete       |         |            |      ✔️      |
| Ver paquete            |   ✔️    |    ✔️      |      ✔️      |
| Tomar foto             |         |    ✔️      |      ✔️      |
| Escanear QR            |         |    ✔️      |      ✔️      |
| Ver mapa               |   ✔️    |    ✔️      |      ✔️      |
| Notificaciones         |   ✔️    |    ✔️      |      ✔️      |
| Dashboard/Exportar     |         |            |    ✔️*       |
| Chat en tiempo real    |   ✔️*   |    ✔️*     |              |

> *✔️*: Permiso limitado o sólo sobre propios paquetes/asignaciones.

---

## 📖 Especificación Detallada del Proyecto

### ✔️ Funcionalidades Clave

- **Autenticación y roles:** Clientes, repartidores y administradores con permisos diferenciados.
- **Gestión de paquetes:** Registro, edición, eliminación (admin), historial de estados, filtrado y asignación.
- **Operaciones con hardware:** Cámara para fotos en registro/entrega; escaneo QR para validar entregas.
- **Localización:** Seguimiento y check-in automático del repartidor al llegar a destino.
- **Notificaciones push:** Alertas automáticas para clientes y repartidores usando FCM.
- **Persistencia local y sincronización:** SQLite y cache para trabajar offline, sincronizando luego con la nube.
- **Interfaz profesional:** Navegación intuitiva, animaciones y feedback visual claro.
- **Backend seguro:** APIs protegidas, manejo de errores y base de datos escalable.

### ➕ Extras opcionales

- **Dashboard administrador** con métricas.
- **Exportar historial** de entregas (PDF/Excel).
- **Ruta optimizada** en el mapa para repartidor.
- **Chat en tiempo real** para coordinación.

### 🔄 Flujo General de la App

1. **Ingreso y autenticación** (según rol).
2. **Visualización de dashboard o lista de paquetes**.
3. **Registro/edición/eliminación de paquetes** (según permisos).
4. **Toma de foto y escaneo QR** en los flujos necesarios.
5. **Visualización de rutas y estados** en el mapa.
6. **Recepción de notificaciones** relevantes.
7. **Sincronización de datos** local/nube, incluso si hay operación offline.
8. **(Opcional) Acceso a dashboard, exportación o chat**.

### 📝 Buenas Prácticas y Metodología

- **Commits:** claros y descriptivos (`feat: pantalla de login`)
- **Branches:** `main`, `develop`, `feature/xyz`
- **Pull Requests:** ligados a issues, revisión obligatoria.
- **Definition of Done (DoD):** Código revisado, probado y documentado.

---

## 💾 Persistencia de Datos

- **Local:** SharedPreferences
- **Sincronización automática** con backend (Firebase)
- **Cache para operación offline**

---

## 🎨 Interfaz de Usuario

- **Tema personalizado** y Material Design
- **Navegación intuitiva** (BottomNavigationBar o Drawer)
- **Animaciones sutiles y responsivas**
- **Manejo de errores:** SnackBars / Dialogs

---

## 📸 Cámara e Imágenes

- **Captura y selección de fotos** (cámara/galería)
- **Vista previa y compresión**
- **Subida a la nube**
- **Manejo de permisos**

---

## 📍 Geolocalización

- **Permisos** y obtención de coordenadas GPS
- **Visualización en Google Maps**
- **Funcionalidad útil:** ubicación de paquetes

---

## 🔔 Notificaciones Push

- **Integración con Firebase Cloud Messaging**
- **Recepción de notificaciones** en foreground/background
- **Navegación desde notificación**

---

## 🚀 Setup Rápido

1. **Clonar repositorio**
   ```bash
   git clone https://github.com/JonthanAyala/Tucanes_DMI_9A.git
   cd Tucanes_DMI_9A
   ```
2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```
3. **Configurar variables de entorno**
   - Copiar `.env.example` → `.env` y llenar datos de Firebase, API, etc.

4. **Ejecutar la app**
   ```bash
   flutter run
   ```

---

## 🏗️ Estructura Base del Proyecto

```
/lib
  /models
  /views
  /viewmodels
  /services
  /utils
  /widgets
/docs
/test
README.md
```

---

## 📝 Convenciones

- **Commits:** español, claros y descriptivos (ej. `feat: pantalla de login`)
- **Branches:** `main`, `develop`, `feature/xyz`
- **Pull Requests:** relacionados a issues, revisión obligatoria

---

### ✅ Definition of Done (DoD)

Una historia o tarea se considera terminada cuando:

- El código está revisado y mergeado.
- Se han pasado las pruebas funcionales básicas.
- La documentación relevante se encuentra actualizada.
- La funcionalidad es visible en la app.
- La issue está cerrada y movida a Done en el tablero.

---

### 📌 Lista de riesgos y mitigaciones

| Riesgo                                 | Mitigación                                    |
|----------------------------------------|-----------------------------------------------|
| Retraso en desarrollo de APIs Backend  | Mockear APIs y avanzar en frontend local      |
| Falta de experiencia con MVVM          | Capacitación previa y uso de ejemplos         |
| Integración Firebase falla             | Seguir documentación oficial y soporte        |
| Falta de tiempo en el sprint           | Priorización de tareas P0, reuniones diarias  |

---

## 📅 Cronograma (Referencia)

| Fase                         | Fechas aprox.            | Entregables                     |
|------------------------------|--------------------------|---------------------------------|
| 📋 Planificación             | Semanas 1-2              | Requerimientos, mockups, docs   |
| 🔧 Backend                   | Semanas 3-4              | APIs, base de datos en nube     |
| 📱 Frontend                  | Semanas 5-8              | App Flutter, MVVM               |
| 🧪 Testing/Optimización      | Semanas 9-10             | Pruebas, optimización           |
| 🚀 Despliegue/Presentación   | Semanas 11-12            | App final, documentación        |

---

## 📚 Documentación

- Documentación técnica y viva en `/docs`
- Manual de usuario, guía de instalación y retrospectiva en `/docs` o Wiki

---

## 👥 Equipo

- [Jonthan Ayala](https://github.com/JonthanAyala)
- [Andres Isai](https://github.com/BojitaNoir)
- [Adrian Hernandez](https://github.com/Aserejex22)
- [Jaime Castañeda](https://github.com/JaimeCAST69)

Docente tiene acceso para revisión.

- [Maximiliano Carsi](https://github.com/carsimax98)

## 🏆 Entrega Final

- Código fuente completo y funcional
- README detallado
- Documentación técnica y de usuario
- APK generado y enlazado
- Video demo y presentación final

---