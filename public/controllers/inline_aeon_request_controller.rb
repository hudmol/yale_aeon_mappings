class InlineAeonRequestController <  ApplicationController
  def form
    uri = params.require(:uri)
    args = {}

    args['resolve[]']  = ['resource:id@compact_resource', 'top_container_uri_u_sstr:id']

    ao = archivesspace.get_record(uri, args)

    series = ao.resolved_top_container['series']
               .select{|s| ao.json['ancestors'].map{|a| a['ref']}.include?(s['ref'])}
               .first

    render :partial => 'inline_aeon_request/form',
           :locals => {:record => ao,
                       :series => series ? series['display_string'] : false,
                       :resource => ao.resolved_resource,
                       :containers => ao.container_titles_and_uris}
  end
end
