# Objetivo

Quiero que construyas una aplicación completa en Ruby on Rails para gestionar un juego de misiones durante una fiesta/cumpleaños.

La aplicación funcionará en un único dispositivo compartido (tipo estación central) al que distintos invitados podrán acercarse para consultar su misión.

No quiero implementar autenticación tradicional, cuentas de usuario, sesiones persistentes ni registro.

La prioridad es que la experiencia sea extremadamente simple y divertida para los invitados.

---

# Filosofía de la aplicación

Esta NO debe sentirse como:

* Software empresarial
* Dashboard corporativo
* Herramienta de productividad
* Sistema administrativo tradicional
* SaaS

Debe sentirse como:

* Un juego de fiesta moderno
* Un juego de mesa llevado a una pantalla
* Un sistema de misiones secretas
* Un álbum de personajes
* Una colección de cartas ilustradas

Referencias conceptuales:

* Dixit
* Exploding Kittens
* Taco Cat
* Coup
* Cartas coleccionables
* Juegos de fiesta modernos

La aplicación debe transmitir inmediatamente que está diseñada para jugar y divertirse.

---

# Stack

Utiliza:

* Ruby on Rails (última versión estable)
* PostgreSQL
* Hotwire/Turbo cuando sea conveniente
* Diseño responsive mobile-first
* Código limpio siguiendo convenciones Rails

---

# Modelo de datos

La aplicación debe separar correctamente:

* Una misión como plantilla permanente
* Una misión asignada a un invitado

Por lo tanto NO quiero guardar current_mission directamente dentro de Guest.

Debe existir un modelo intermedio para representar asignaciones.

---

# Modelos

## Guest

Representa un invitado.

Campos:

```ruby
name:string
phone:string
email:string
picture:string
points:integer default: 0
attempts:integer default: 1
```

Validaciones:

* name obligatorio
* points >= 0
* attempts >= 0

Relaciones:

```ruby
has_many :mission_assignments,
         dependent: :destroy

has_one :active_assignment,
        -> { where(status: :assigned) },
        class_name: "MissionAssignment"

has_one :current_mission,
        through: :active_assignment,
        source: :mission
```

---

## Mission

Representa una plantilla de misión.

Campos:

```ruby
description:text
score:integer
active:boolean default: true
```

Validaciones:

* description obligatorio
* score > 0

Relaciones:

### target

Cada misión tiene exactamente un invitado objetivo.

```ruby
belongs_to :target,
           class_name: "Guest"
```

### restricted_guests

Lista de invitados que NO pueden recibir esta misión.

```ruby
has_and_belongs_to_many :restricted_guests,
                        class_name: "Guest"
```

### target_guests

Lista de invitados involucrados en la misión.

```ruby
has_and_belongs_to_many :target_guests,
                        class_name: "Guest"
```

Además:

```ruby
has_many :mission_assignments
```

---

## MissionAssignment

Representa una misión asignada a un invitado.

Campos:

```ruby
guest_id:references
mission_id:references

status:integer

assigned_at:datetime
completed_at:datetime
```

Enum:

```ruby
enum status: {
  assigned: 0,
  completed: 1,
  abandoned: 2
}
```

Relaciones:

```ruby
belongs_to :guest
belongs_to :mission
```

Validación obligatoria:

Un invitado no puede tener más de una misión activa simultáneamente.

---

# Lógica de negocio

## Asignar misión

Cuando un invitado solicita una misión:

* Debe tener cero misiones activas
* Debe encontrarse una misión válida
* La misión debe estar activa
* El invitado no puede estar en restricted_guests

Crear:

```ruby
MissionAssignment.create!(
  guest: guest,
  mission: mission,
  status: :assigned,
  assigned_at: Time.current
)
```

---

## Cambiar misión

Requisitos:

```ruby
guest.attempts > 0
```

Proceso:

1. Marcar asignación actual como abandoned
2. Restar un intento
3. Buscar nueva misión válida
4. Crear nueva asignación

Nunca eliminar historial.

---

## Completar misión

Solo un administrador puede hacerlo.

Proceso:

```ruby
assignment.update!(
  status: :completed,
  completed_at: Time.current
)

guest.increment!(
  :points,
  assignment.mission.score
)
```

Después de completarla:

* El invitado queda sin misión activa
* Puede solicitar otra misión

---

# Flujo público

## Home

Ruta raíz.

Mostrar todos los invitados creados.

Cada tarjeta debe mostrar:

* Foto
* Nombre

Diseño tipo galería.

Las tarjetas deben parecer personajes seleccionables.

Al tocar una tarjeta comienza el flujo de verificación.

---

# Flujo de verificación

Pantalla 1:

"Eres José?"

Botón:

"Sí"

---

Pantalla 2:

"¿Estás seguro de que eres José?"

Botón:

"Sí, estoy seguro"

---

Pantalla 3:

"No mientas, por favor asegúrate de ser José. Haz clic para ver tu misión."

Botón:

"Ver mi misión"

---

Solo después de los tres pasos se accede al perfil.

Esto NO es seguridad real.

Es solamente una barrera social divertida.

---

# Vista del invitado

Mostrar:

* Foto grande
* Nombre
* Puntos actuales
* Intentos restantes

---

## Si existe misión activa

Mostrar:

* Descripción
* Puntaje

Botón:

"Cambiar misión"

Solo si attempts > 0.

---

## Si NO existe misión activa

Mostrar:

"Asignar nueva misión"

Al presionarlo:

* Asignar automáticamente una misión válida

---

## Si no quedan intentos

No mostrar el botón de cambio.

Mostrar mensaje amigable indicando que ya utilizó todos sus cambios.

---

# Administración

Ruta:

```text
/admin
```

---

# Acceso administrador

No implementar autenticación tradicional.

Al entrar:

Mostrar formulario.

Texto:

"Ingresa la palabra secreta"

Palabra:

```text
kikito
```

Si coincide:

Acceder al panel.

Si no coincide:

Mostrar error.

---

# Dashboard administrador

Secciones:

* Invitados
* Misiones
* Asignaciones
* Ranking

---

# Gestión de invitados

CRUD completo.

Permitir:

* Crear
* Editar
* Eliminar

Campos editables:

* nombre
* teléfono
* email
* foto
* puntos
* intentos

---

# Gestión de misiones

CRUD completo.

Campos:

* descripción
* puntaje
* target
* restricted_guests
* target_guests
* active

Los invitados relacionados deben seleccionarse mediante controles visuales amigables.

---

# Gestión de asignaciones

Permitir:

* Ver todas
* Filtrar por estado
* Crear manualmente
* Editar
* Eliminar

Mostrar:

* invitado
* misión
* estado
* fecha asignación
* fecha completada

---

# Confirmación de misión

Desde una asignación activa.

Botón:

"Confirmar misión completada"

Acciones:

1. Cambiar estado a completed
2. Registrar completed_at
3. Sumar puntos
4. Mantener historial

Esta debe ser la única forma válida de ganar puntos.

---

# Historial

Cada invitado debe tener historial completo.

Mostrar:

* misión
* estado
* fecha asignación
* fecha completada

Utilizando:

```ruby
guest.mission_assignments
```

---

# Ranking

Vista exclusiva para administrador.

Ordenar por:

1. points DESC
2. name ASC

Columnas:

* posición
* foto
* nombre
* puntos

Resaltar:

* primer lugar
* segundo lugar
* tercer lugar

---

# Dirección artística

## Objetivo visual

La aplicación debe sentirse como un juego de mesa moderno llevado a una pantalla móvil.

Las ilustraciones de los invitados serán subidas posteriormente y deben ser protagonistas de la experiencia.

La interfaz debe estar diseñada alrededor de esas ilustraciones.

---

# Estilo visual

Usar:

* Esquinas muy redondeadas
* Tarjetas redondeadas
* Botones redondeados
* Chips y badges redondeados
* Sombras suaves
* Espaciado generoso
* Componentes grandes
* Mucho aire visual
* Jerarquía clara

Evitar:

* Esquinas rectas
* Tablas densas
* Apariencia Bootstrap
* Apariencia Material Design estándar
* Interfaces empresariales
* Apariencia de software administrativo

---

# Estilo de ilustración

Las imágenes de los invitados deben sentirse como personajes coleccionables.

Las tarjetas de invitados deben parecer:

* Cartas de personaje
* Tarjetas coleccionables
* Avatares de juego

No deben parecer perfiles corporativos.

---

# Tarjetas de invitados

Diseño:

* Imagen grande
* Nombre destacado
* Badge decorativo opcional
* Sombra suave

Deben verse seleccionables y entretenidas.

---

# Tarjetas de misión

Las misiones deben sentirse como cartas especiales.

Diseño:

* Puntaje muy visible
* Descripción clara
* Apariencia de "misión secreta"

La misión debe sentirse importante y emocionante.

---

# Paleta de colores

Inspirarse en estas paletas:

Paleta principal:

```text
#073B4C
#118AB2
#06D6A0
```

Colores de énfasis:

```text
#EF476F
#FFD166
```

Uso recomendado:

* Azules y verdes como base visual
* Amarillo para recompensas y destacados
* Rosado para acciones especiales y elementos llamativos

No usar todos los colores con la misma intensidad.

Priorizar armonía y legibilidad.

---

# Interacciones

La aplicación será usada principalmente en móviles.

No utilizar hover como elemento importante.

Las acciones deben diseñarse para:

* Tap
* Click
* Touch

Agregar microinteracciones suaves:

* Escala ligera al tocar botones
* Aparición elegante de tarjetas
* Transiciones suaves

Evitar:

* Rebotes exagerados
* Efectos flashy
* Animaciones excesivas

---

# Dark Mode

NO depender del tema del sistema operativo.

Definir explícitamente:

* Fondo
* Texto
* Bordes
* Sombras
* Colores de componentes

La aplicación debe verse igual independientemente del modo oscuro o claro del dispositivo.

---

# Seeds

Generar seeds completos.

Crear:

* Invitados de ejemplo
* Misiones de ejemplo
* Relaciones de ejemplo
* Imágenes placeholder

La aplicación debe quedar utilizable inmediatamente después de:

```bash
rails db:seed
```

---

# Entregables

Generar:

1. Modelos
2. Migraciones
3. Relaciones
4. Validaciones
5. Enums
6. Tablas HABTM
7. Rutas
8. Controladores
9. Servicios para asignación automática
10. Dashboard administrador
11. Vistas públicas
12. Vistas administrativas
13. Seeds
14. Diseño responsive mobile-first
15. Estilos completos
16. Instrucciones de ejecución

La aplicación debe quedar completamente funcional, consistente y lista para ejecutarse localmente.
