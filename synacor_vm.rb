class SynacorVm
  attr_reader :registers, :program, :halt, :pos

  def initialize(input = '')
    @registers = 8.times.map { 0 }
    @program = input.split(',').map(&:to_i)
    @halt = false
    @pos = 0
  end

  def get_arg
    a = @program[@pos]
    a_val = a && a >= 32768 ? @registers[a - 32768] : a
    @pos += 1
    [a, a_val]
  end

  def step(op)
    case op
    when 0 # halt
      @halt = true
    when 9 # add
      a, _ = get_arg
      _, b_val = get_arg
      _, c_val = get_arg
      @registers[a - 32768] = (b_val + c_val) % 32768
    when 19 # out
      _, a_val = get_arg
      print a_val.chr
    when 21 #noop
    else
      puts "Unhandled OpCode encountered: ${op}"
      @halt = true
    end
  end

  def run
    while !halt do
      op, _ = get_arg
      op ||= 0
      step(op)
    end
  end
end
