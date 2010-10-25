atom_feed do |feed|
  feed.title("#{@project.name}-&gt;#{@type.name}")
  feed.updated(@stories.first.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ"))
 
  for story in @stories
    next if story.updated_at.blank?
    feed.entry([@project, @type, story]) do |entry|
      entry.title(story.headline)
      entry.content(story.text, :type =&gt; 'html')
      entry.updated(story.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ")) # needed to work with Google Reader.
      entry.author do |author|
        author.name(story.author)
      end
    end
  end
end