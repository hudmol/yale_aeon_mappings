class YaleAeonUtils

  def self.doc_type(settings, id)
    resource_id_map(settings[:document_type_map], id)
  end


  def self.web_request_form(settings, id)
    resource_id_map(settings[:web_request_form_map], id)
  end


  def self.resource_id_map(id_map, id)
    return '' unless id_map

    default = id_map.fetch(:default, '')

    if id
      val = id_map.select {|k,v| id.start_with?(k.to_s)}.values.first
      return val if val
    end

    return default
  end

end
