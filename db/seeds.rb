# frozen_string_literal: true

# Seeds para testar o sistema de tracking em tempo real
puts "🌱 Populando banco com dados de teste..."

# Criar conta
account = Account.find_or_create_by!(name: "NaviDelivery Demo") do |acc|
  puts "   ✅ Criando conta: #{acc.name}"
end

# Criar usuário admin
user = User.find_or_create_by!(email: "admin@navidelivery.com") do |u|
  u.password = "123456"
  u.password_confirmation = "123456"
  u.name = "Admin Demo"
  u.account = account
  puts "   ✅ Criando usuário: #{u.email}"
end

# Criar loja
store = Store.find_or_create_by!(name: "Loja Centro SP") do |s|
  s.address = "Av. Paulista, 1000, São Paulo, SP"
  s.latitude = -23.5505
  s.longitude = -46.6333
  s.account = account
  puts "   ✅ Criando loja: #{s.name}"
end

# Criar courier (motoboy)
courier = Courier.find_or_create_by!(name: "João Silva") do |c|
  c.phone = "+5511999999999"
  c.address = "Rua Augusta, 100, São Paulo, SP"
  c.latitude = -23.5520
  c.longitude = -46.6360
  c.account = account
  puts "   ✅ Criando courier: #{c.name}"
end

# Criar cliente
customer = Customer.find_or_create_by!(name: "Maria Santos") do |c|
  c.phone = "+5511888888888"
  c.address = "Rua Augusta, 500, São Paulo, SP"
  c.latitude = -23.5535
  c.longitude = -46.6390
  c.account = account
  puts "   ✅ Criando cliente: #{c.name}"
end

# Criar entrega de teste
delivery = Delivery.find_or_create_by!(external_order_code: "DEMO001") do |d|
  d.account = account
  d.store = store
  d.courier = courier
  d.customer = customer
  d.user = user
  d.status = "assigned"
  d.pickup_address = store.address
  d.dropoff_address = customer.address
  d.pickup_location = "POINT(#{store.longitude} #{store.latitude})"
  d.dropoff_location = "POINT(#{customer.longitude} #{customer.latitude})"
  puts "   ✅ Criando entrega: #{d.external_order_code}"
end

puts ""
puts "🎉 Dados de teste criados com sucesso!"
puts ""
puts "📋 Dados criados:"
puts "   👤 Usuário: admin@navidelivery.com (senha: 123456)"
puts "   🏪 Loja: #{store.name}"
puts "   🏍️ Courier: #{courier.name}"
puts "   👨‍👩‍👧‍👦 Cliente: #{customer.name}"
puts "   📦 Entrega: #{delivery.external_order_code}"
puts ""
puts "🔗 Link de tracking público:"
puts "   http://localhost:3000/track/#{delivery.public_token}"
puts ""
puts "🧪 Para testar o simulador do motoboy:"
puts "   1. Acesse o console: docker-compose exec web bundle exec rails console"
puts "   2. Execute:"
puts "      delivery = Delivery.find_by(external_order_code: 'DEMO001')"
puts "      simulator = CourierAppSimulator.new(delivery.public_token)"
puts "      simulator.start_tracking_simulation"
puts ""
puts "   3. Abra o link de tracking em outra aba do navegador para ver em tempo real!"
puts ""
puts "✅ Seeds executados com sucesso!"
