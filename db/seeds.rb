# Devise user for SPA / JWT (change password after first login in production).
User.find_or_create_by!(email: 'admin@example.com') do |u|
  u.password = 'Password1!'
  u.password_confirmation = 'Password1!'
end

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Coppola family tree
# Get from https://en.wikipedia.org/wiki/Coppola_family_tree

# creating persons
italia  = Person.create(first_name: 'Italia', last_name: 'Pennino', gender: 'female', date_of_birth: '1912-12-12', date_of_death: '2004-01-21')
carmine = Person.create(first_name: 'Carmine', last_name: 'Coppola', gender: 'male', date_of_birth: '1910-11-06', location_of_birth: 'New York City, New York, U.S.', date_of_death: '1991-04-26', location_of_death: 'Northridge, California, U.S.', bio: 'American composer, flautist, editor, musical director, and songwriter.')
# anton   = Person.create(first_name: 'Anton', last_name: 'Coppola', gender: 'male', date_of_birth: '1917', bio: 'American opera conductor and composer')
joy     = Person.create(first_name: 'Joy', last_name: 'Vogelsang', gender: 'female')
august  = Person.create(first_name: 'August Floyd', last_name: 'Coppola', gender: 'male', date_of_birth: '1934-02-16', location_of_birth: 'Hartford, Connecticut, U.S.', date_of_death: '2009-10-27', location_of_death: 'Los Angeles, California, U.S.', bio: 'American academic, author, film executive and advocate for the arts.')
nicolas = Person.create(first_name: 'Nicolas Kim', last_name: 'Coppola', gender: 'male', date_of_birth: '1964-01-07', location_of_birth: 'Long Beach, California, U.S.', bio: 'Known professionally as Nicolas Cage, is an American actor, director and producer.')
alice   = Person.create(first_name: 'Alice', last_name: 'Kim', gender: 'female')
christy = Person.create(first_name: 'Christina', last_name: 'Fulton', gender: 'female', date_of_birth: '1962-07-26', location_of_birth: 'Boise, Idaho, U.S.')
kal_el  = Person.create(first_name: 'Kal-El', last_name: 'Coppola Cage', gender: 'male', date_of_birth: '2005-10-03')
weston  = Person.create(first_name: 'Weston', last_name: 'Coppola Cage', gender: 'male', date_of_birth: '1990-12-26')

# updating parentships
 weston.parentship.update( father: nicolas, mother: christy )
 kal_el.parentship.update( father: nicolas, mother: alice   )
nicolas.parentship.update( father: august,  mother: joy     )
 august.parentship.update( father: carmine, mother: italia  )

# creating partnerships
Partnership.create([
  { person: nicolas, partner: alice   },
  { person: nicolas, partner: christy },
  { person: august,  partner: joy     },
  { person: carmine, partner: italia  }
])

# attach avatars (disable for heroku)
  italia.avatar.attach( io: File.open(Rails.root.join('db/example_images/italia.png')),  filename: 'italia.png'  )
 carmine.avatar.attach( io: File.open(Rails.root.join('db/example_images/carmine.png')), filename: 'carmine.png' )
  august.avatar.attach( io: File.open(Rails.root.join('db/example_images/august.png')),  filename: 'august.png'  )
 nicolas.avatar.attach( io: File.open(Rails.root.join('db/example_images/nicolas.png')), filename: 'nicolas.png' )
   alice.avatar.attach( io: File.open(Rails.root.join('db/example_images/alice.png')),   filename: 'alice.png'   )
 christy.avatar.attach( io: File.open(Rails.root.join('db/example_images/christy.jpg')), filename: 'christy.jpg' )