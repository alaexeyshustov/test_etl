class AbstractChannel

  def initialize(_queue)
    raise 'Abstrract method'
  end

  def notify(*_args)
    raise 'Abstract method'
  end

end
