# frozen_string_literal: true
#
# Seeds — Misiones App
#
# Idempotente: usa find_or_create_by! en invitados y misiones.
# Ejecutar con: rails db:seed
# Para reset limpio: rails db:schema:load db:seed

puts "🌱 Sembrando datos..."

# ── Limpiar asignaciones para poder re-seedear sin conflictos ────────────────
MissionAssignment.delete_all

# ── Invitados ────────────────────────────────────────────────────────────────
#
# Las imágenes usan ui-avatars.com, que genera un avatar con iniciales
# a partir del nombre. No requiere cuenta ni API key, funciona offline-first
# (el browser cachea la imagen tras la primera carga).

guests_data = [
  {
    name:     "Valentina Cruz",
    phone:    "555-0101",
    email:    "valentina@fiesta.local",
    picture:  "https://ui-avatars.com/api/?name=Valentina+Cruz&size=400&background=EF476F&color=fff&bold=true&rounded=true",
    points:   0,
    attempts: 2
  },
  {
    name:     "Marcos Ríos",
    phone:    "555-0102",
    email:    "marcos@fiesta.local",
    picture:  "https://ui-avatars.com/api/?name=Marcos+Rios&size=400&background=118AB2&color=fff&bold=true&rounded=true",
    points:   0,
    attempts: 2
  },
  {
    name:     "Sofía Mendez",
    phone:    "555-0103",
    email:    "sofia@fiesta.local",
    picture:  "https://ui-avatars.com/api/?name=Sofia+Mendez&size=400&background=06D6A0&color=073B4C&bold=true&rounded=true",
    points:   0,
    attempts: 2
  }
]

guests = guests_data.map do |attrs|
  g = Guest.find_or_create_by!(name: attrs[:name]) do |record|
    record.assign_attributes(attrs)
  end
  # Ensure mutable fields are up-to-date on re-seed
  g.update!(attrs.except(:name))
  puts "  👤 #{g.name}"
  g
end

valentina, marcos, sofia = guests

# ── Misiones ─────────────────────────────────────────────────────────────────
#
# Cada misión tiene un target (el invitado protagonista de la misión),
# un score y una descripción divertida de fiesta.

missions_data = [
  {
    description: "Consigue que #{valentina.name} te enseñe su mejor baile sin que sepa que es tu misión. Tienes 5 minutos.",
    score:       20,
    active:      true,
    target:      valentina
  },
  {
    description: "Convence a #{marcos.name} de que cante aunque sea una estrofa de una canción frente a todos.",
    score:       25,
    active:      true,
    target:      marcos
  },
  {
    description: "Haz que #{sofia.name} te cuente un secreto (puede ser inventado). El chiste es que lo diga en voz alta.",
    score:       15,
    active:      true,
    target:      sofia
  },
  {
    description: "Tómate una foto grupal con al menos 4 personas que incluya al menos dos de los invitados especiales. Muéstrasela al admin para ganar los puntos.",
    score:       30,
    active:      true,
    target:      valentina
  },
  {
    description: "Organiza un brindis de al menos 6 personas. Tú debes dar el discurso. No importa si es corto.",
    score:       35,
    active:      true,
    target:      marcos
  }
]

missions = missions_data.map.with_index(1) do |attrs, i|
  m = Mission.find_or_create_by!(description: attrs[:description]) do |record|
    record.assign_attributes(attrs)
  end
  m.update!(attrs.except(:description))
  puts "  🎯 Misión #{i}: #{attrs[:description].truncate(60)}"
  m
end

baile, karaoke, secreto, foto_grupal, brindis = missions

# ── Relaciones HABTM ─────────────────────────────────────────────────────────

puts "  🔗 Configurando restricciones y target_guests..."

# Un invitado no puede recibir una misión que lo tiene como objetivo.
# Tampoco tiene sentido que alguien espíe su propia misión.

# Misión baile: valentina es el target → valentina no puede recibirla
baile.restricted_guests = [ valentina ]
baile.target_guests     = [ valentina, marcos ]   # los involucrados

# Misión karaoke: marcos es el target → marcos no puede recibirla
karaoke.restricted_guests = [ marcos ]
karaoke.target_guests     = [ marcos, sofia ]

# Misión secreto: sofia es el target → sofia no puede recibirla
secreto.restricted_guests = [ sofia ]
secreto.target_guests     = [ sofia ]

# Foto grupal: involucra a todos, valentina es target pero puede recibirla
# (la misión es de ella hacia los demás)
foto_grupal.restricted_guests = []
foto_grupal.target_guests     = [ valentina, marcos, sofia ]

# Brindis: misión libre, nadie restringido
brindis.restricted_guests = []
brindis.target_guests     = [ valentina, marcos, sofia ]

# ── Asignaciones de ejemplo ───────────────────────────────────────────────────
#
# Dejamos a cada invitado en un estado diferente para poder probar todos
# los flujos inmediatamente tras el seed:
#
#   valentina → misión activa asignada (puede cambiarla, tiene 2 intentos)
#   marcos    → sin misión activa (puede solicitar una)
#   sofia     → misión completada en historial + sin misión activa

puts "  📋 Creando asignaciones de ejemplo..."

# Valentina: misión activa
MissionAssignment.create!(
  guest:       valentina,
  mission:     karaoke,           # karaoke no la tiene en restricted_guests
  status:      :assigned,
  assigned_at: 10.minutes.ago
)
puts "  ✅ #{valentina.name} → asignada a \"#{karaoke.description.truncate(40)}\""

# Sofía: una misión completada en el historial (sumamos los puntos manualmente)
completed = MissionAssignment.create!(
  guest:        sofia,
  mission:      foto_grupal,
  status:       :completed,
  assigned_at:  1.hour.ago,
  completed_at: 30.minutes.ago
)
sofia.update!(points: foto_grupal.score)
puts "  🏆 #{sofia.name} → completó \"#{foto_grupal.description.truncate(40)}\" (+#{foto_grupal.score} pts)"

# Marcos: sin asignación activa, listo para solicitar una
puts "  ⏳ #{marcos.name} → sin misión activa"

# ── Resumen ───────────────────────────────────────────────────────────────────

puts ""
puts "✅ Seed completo."
puts "   Invitados:   #{Guest.count}"
puts "   Misiones:    #{Mission.count}"
puts "   Asignaciones: #{MissionAssignment.count}"
puts ""
puts "   Estado de invitados:"
Guest.order(:name).each do |g|
  status = if g.active_assignment
    "🟡 misión activa: \"#{g.current_mission.description.truncate(35)}\""
  elsif g.mission_assignments.completed.any?
    "🟢 sin misión activa (#{g.points} pts acumulados)"
  else
    "⚪ sin misión aún"
  end
  puts "   • #{g.name.ljust(20)} #{status}"
end
puts ""
puts "   Admin: GET /admin/login → palabra secreta: kikito"
