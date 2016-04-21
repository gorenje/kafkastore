class Range
  def to_json(*a)
    {
      'json_class'   => self.class.name,
      'data'         => [ first, last, exclude_end? ]
    }.to_json(*a)
  end

  def self.json_create(o)
    new(*o['data'])
  end
end
