require 'rubygems'
require 'json'
require "net/http"
require "uri"
require 'faker'
require 'active_support/time'



# ---------------------------------------------------------------------------------------------------



$host = ENV['EP_HOST']
$shop = ENV['EP_SHOP']
$token = ENV['EP_TOKEN']

if ($host.nil? || $shop.nil? || $token.nil?)
    puts 'Please set the environment variables EP_HOST, EP_SHOP and EP_TOKEN!'
    exit
end


$numberOfCartsToCreate = ENV['EP_CART_TO_CREATE'] || 10
$maxNumberOfDifferentLineItems = ENV['EP_MAX_LINEITEMS_PER_CART'] || 3
$maxNumberOfProductsPerLineItem = ENV['EP_MAX_PRODUCTS_PER_LINEITEM'] || 5



# ---------------------------------------------------------------------------------------------------



def changeStockLevelOfProduct(productId, deltaStocklevel)
    stockLevelUpdateHash = [{
        :op => 'add',
        :path => '/stocklevel',
        :value => deltaStocklevel,
    }]
    stockLevelUpdateJson = JSON.generate(stockLevelUpdateHash)

    uri = URI.parse($host)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Patch.new('/rs/shops/'+$shop+'/products/'+productId)
    request.add_field('Authorization', 'Bearer '+$token)
    request.add_field('Content-Type', 'application/json')
    request.body = stockLevelUpdateJson

    response = http.request(request)

    puts 'changed stocklevel of product '+productId+' by '+deltaStocklevel.to_s+': '+response.code
end



def createCartInput(productIds)
    lineItems = []

    numberOfDifferentLineItems = 1 + Random.rand($maxNumberOfDifferentLineItems)
    numberOfDifferentLineItems.times do
        lineItems.push(
            {
                :productId => productIds[Random.rand(productIds.length)],
                :quantity => 1 + Random.rand($maxNumberOfProductsPerLineItem),
            }
        )
    end

    cartInput = {
        :currency => 'EUR',
        :taxType => 'GROSS',
        :locale => 'en_GB',
        :lineItems => lineItems,
    }

    return JSON.generate(cartInput)
end



def createCart(cartInputJson)

    uri = URI.parse($host)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new('/rs/shops/'+$shop+'/carts/')
    request.add_field('Authorization', 'Bearer '+$token)
    request.add_field('Content-Type', 'application/json')
    request.body = cartInputJson

    response = http.request(request)

    cartJson = response.body
    cart = JSON.parse(cartJson)
    cartId = cart['cartId']
    puts 'created Cart '+cartId+': '+response.code
    
    return cartId
end



def addRandomBillingAddressToCart(cartId)

    billingAddressHash = {
        :firstName => Faker::Name.first_name,
        :lastName => Faker::Name.last_name,
        :street => Faker::Address.street_address,
        :zipCode => Faker::Address.zip_code,
        :city => Faker::Address.city,
        :country => Faker::Address.country_code,
        :emailAddress => Faker::Internet.email,
        :company => Faker::Company.name,
        :title => Faker::Name.title,
    }
    billingAddressJson = JSON.generate(billingAddressHash)

    uri = URI.parse($host)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Put.new('/rs/shops/'+$shop+'/carts/'+cartId+'/billing-address')
    request.add_field('Authorization', 'Bearer '+$token)
    request.add_field('Content-Type', 'application/json')
    request.body = billingAddressJson

    response = http.request(request)

    puts 'added BillingAddress to cart '+cartId+': '+response.code
end



def createOrderFromCart(cartId)

    uri = URI.parse($host)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new('/rs/shops/'+$shop+'/carts/'+cartId+'/order')
    request.add_field('Authorization', 'Bearer '+$token)
    request.add_field('Content-Type', 'application/json')
    request.add_field('Accept', 'application/vnd.epages.v1+json')

    response = http.request(request)

    puts 'created order from cart '+cartId+': '+response.code
end



# ---------------------------------------------------------------------------------------------------



# GET /products
uri = URI.parse($host)
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new('/rs/shops/'+$shop+'/products/?resultsPerPage=100')
response = http.request(request)
productsJson = response.body



# extract productIds
products = JSON.parse(productsJson)
items = products['items']
productIds = items.map do |product|
    product['productId']
end



# increase stocklevels
deltaStocklevel = $maxNumberOfProductsPerLineItem * $maxNumberOfDifferentLineItems * $numberOfCartsToCreate
productIds.each do |productId|
    changeStockLevelOfProduct(productId, deltaStocklevel)
end



# create orders
$numberOfCartsToCreate.times do |i|

    puts "\n"

    cartInputJson = createCartInput(productIds)

    cartId = createCart(cartInputJson)

    addRandomBillingAddressToCart(cartId)

    createOrderFromCart(cartId)

end
