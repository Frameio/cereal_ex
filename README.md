# Cereal

Cereal is a Pluggable JSON Serialization layer. It allows you to define Serializers
to convert structs into an abstract format and then serialize those formats into JSON
in whichever way you wish.

## Features

* Customizable JSON serializer for entities and for errors
* Sparse fieldset support
* Dynamic include support
* `:has_one`, `:has_many`, `:embeds_one` relationships for your entities
