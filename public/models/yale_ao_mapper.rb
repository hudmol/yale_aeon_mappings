class YaleAeonAOMapper < AeonArchivalObjectMapper

    def record_fields
        mappings = super

        mappings['title'] = 'WEEEEEE'

        mappings
    end
end
