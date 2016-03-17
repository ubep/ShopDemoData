This project contains two scripts to generate demo orders:

- The *createOrders.rb* connects via the REST API
to the shop and creates a certain amount of orders with a random amount of random products and a random billing address. It can be run from everywhere, you only need a Ruby installation.
- The second script, *setRandomOrderCreationDates.pl* allows you to change the CreationDate attribute of the orders to random values of a given range
(Orders created with the first script have the current date as CreationDate).
This script can only be run on the machine where the shop is installed.

## Creating orders using *createOrders.rb*

The script reads a few environment variables which have to be set first.

These are all available variables which can or have to be set:

Name | Description | Required? | Default
--- | --- | --- | ---
EP_HOST | url of the machine where the shop runs | yes |
EP_SHOP | name of the shop where the orders should be created | yes |
EP_TOKEN | token for the REST API (required) | yes |
EP_CART_TO_CREATE | number of orders to create | no | 10
EP_MAX_LINEITEMS_PER_CART | max. number of line items per order | no | 3
EP_MAX_PRODUCTS_PER_LINEITEM | max. number of products per line item | no | 5
ORDERSFILE | file to store the GUIDs of the created orders | no |

If you want to run the script from a shell script, it could look like this:

    #!/bin/bash
    export EP_HOST=http://shopmachine
    export EP_SHOP=DemoShop
    export EP_TOKEN=CXudJp5oXJbrYnz8QJk2cNGgW0sZscFa
    ruby createOrders.rb



## Changing the order dates using *setRandomOrderCreationDates.pl*

To change the attribute *CreationDate* of the orders created with *createOrders.rb*,
you need their GUIDs. Before running *createOrders.rb* set the environment variable *ORDERSFILE*, e.g. like this:

    export ORDERSFILE=orderguids

and the script will create a file with the given name containing all the GUIDs of the created orders.

If you have the file with the GUIDs, you can run the Perl script to change the creation dates of the orders belonging to the GUIDs:

    $PERL setRandomOrderCreationDates.pl -storename Store -ordersfile orderguids -startdate 2010-01-01 -enddate 2016-03-14

The following arguments are required:

Name | Description | Example
--- | --- | ---
storename | name of the store | Store
ordersfile | name of the file containing the GUIDs | orderguids
startdate | start of the random date range | 2010-01-01
enddate | end of the random date range | 2016-03-14

