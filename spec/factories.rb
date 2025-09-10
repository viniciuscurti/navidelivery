FactoryBot.define do
  factory :account do
    name { Faker::Company.name }
    status { :active }

    trait :inactive do
      status { :inactive }
    end

    trait :suspended do
      status { :suspended }
    end
  end

  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    phone { '+5511999999999' }
    role { :user }
    status { :active }
    account

    trait :admin do
      role { :admin }
    end

    trait :store_manager do
      role { :store_manager }
    end

    trait :courier do
      role { :courier }
    end

    trait :super_admin do
      role { :super_admin }
      account { nil }
    end

    trait :inactive do
      status { :inactive }
    end

    trait :suspended do
      status { :suspended }
    end
  end

  factory :store do
    name { Faker::Company.name }
    address { Faker::Address.full_address }
    account

    trait :with_coordinates do
      latitude { -23.5505 }
      longitude { -46.6333 }
    end
  end

  factory :courier do
    name { Faker::Name.name }
    phone { '+5511777777777' }
    account

    trait :with_coordinates do
      latitude { -23.5505 }
      longitude { -46.6333 }
      address { Faker::Address.full_address }
    end

    trait :unavailable do
      status { :unavailable }
    end

    trait :busy do
      status { :busy }
    end
  end

  factory :customer do
    name { Faker::Name.name }
    phone { '+5511666666666' }
    address { Faker::Address.full_address }
    account

    trait :with_coordinates do
      latitude { -23.5489 }
      longitude { -46.6388 }
    end
  end

  factory :delivery do
    external_order_code { Faker::Alphanumeric.alphanumeric(number: 10).upcase }
    pickup_address { Faker::Address.full_address }
    dropoff_address { Faker::Address.full_address }
    pickup_location { RGeo::Geographic.spherical_factory(srid: 4326).point(-46.6333094, -23.5505199) }
    dropoff_location { RGeo::Geographic.spherical_factory(srid: 4326).point(-46.6444444, -23.5666666) }
    status { 'pending' }
    public_token { SecureRandom.urlsafe_base64(32) }
    account
    store
    customer

    trait :assigned do
      status { 'assigned' }
      courier
    end

    trait :en_route do
      status { 'en_route' }
      courier
    end

    trait :delivered do
      status { 'delivered' }
      courier
    end
  end

  factory :location_ping do
    location { RGeo::Geographic.spherical_factory(srid: 4326).point(-46.6333094, -23.5505199) }
    pinged_at { Time.current }
    courier
    delivery
  end

  factory :route do
    distance_meters { rand(1000..50000) }
    duration_seconds { rand(300..3600) }
    polyline { 'encoded_polyline_string' }
    delivery
  end
end
