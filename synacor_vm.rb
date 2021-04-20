class SynacorVm
  attr_reader :registers, :program, :halt, :pos, :stack

  def initialize(input = '')
    @registers = 8.times.map { 0 }
    @program = input.split(',').map(&:to_i)
    @halt = false
    @pos = 0
    @stack = []
    @stdin_buffer = []
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
    when 1 # set
      a, _ = get_arg
      _, b_val = get_arg
      @registers[a - 32768] = b_val
    when 2 # push
      _, a_val = get_arg
      @stack.push(a_val)
    when 3 # pop
      a, _ = get_arg
      raise "Stack Empty!" if @stack.empty?
      @registers[a - 32768] = @stack.pop
    when 4 # eq
      a, _ = get_arg
      _, b_val = get_arg
      _, c_val = get_arg
      @registers[a - 32768] = b_val == c_val ? 1 : 0
    when 5 # eq
      a, _ = get_arg
      _, b_val = get_arg
      _, c_val = get_arg
      @registers[a - 32768] = b_val > c_val ? 1 : 0
    when 6 # jmp
      _, a_val = get_arg
      @pos = a_val
    when 7 # jt
      _, a_val = get_arg
      _, b_val = get_arg
      @pos = b_val if !a_val.zero?
    when 8 # jf
      _, a_val = get_arg
      _, b_val = get_arg
      @pos = b_val if a_val.zero?
    when 9 # add
      a, _ = get_arg
      _, b_val = get_arg
      _, c_val = get_arg
      @registers[a - 32768] = (b_val + c_val) % 32768
    when 10 # mult
      a, _ = get_arg
      _, b_val = get_arg
      _, c_val = get_arg
      @registers[a - 32768] = (b_val * c_val) % 32768
    when 11 # mod
      a, _ = get_arg
      _, b_val = get_arg
      _, c_val = get_arg
      @registers[a - 32768] = b_val % c_val
    when 12 # and
      a, _ = get_arg
      _, b_val = get_arg
      _, c_val = get_arg
      @registers[a - 32768] = b_val & c_val
    when 13 # or
      a, _ = get_arg
      _, b_val = get_arg
      _, c_val = get_arg
      @registers[a - 32768] = b_val | c_val
    when 14 # not - 15-bit inverse
      a, _ = get_arg
      _, b_val = get_arg
      val = 0
      15.times do |n|
        val += 2**n if b_val[n] == 0
      end
      @registers[a - 32768] = val
    when 15 # rmem
      a, _ = get_arg
      _, b_val = get_arg
      @registers[a - 32768] = @program[b_val]
    when 16 # wmem
      _, a_val = get_arg
      _, b_val = get_arg
      @program[a_val] = b_val
    when 17 # call
      _, a_val = get_arg
      @stack.push(@pos)
      @pos = a_val
    when 18 # ret
      if @stack.empty?
        @halt = true
      else
        @pos = @stack.pop
      end
    when 19 # out
      _, a_val = get_arg
      print a_val.chr
    when 20 # in
      # puts "Prog: #{@program[@pos...(@pos+10)]}"
      # puts "Reg: #{@registers}"
      a, _ = get_arg
      if @stdin_buffer.empty?
        @stdin_buffer = STDIN.gets().chars.map(&:ord)
      end
      @registers[a - 32768] = @stdin_buffer.shift
    when 21 #noop
    else
      puts "Unhandled OpCode encountered: #{op} @ #{@pos}"
      puts "Potential Args: #{get_arg} #{get_arg} #{get_arg}"
      @pos -= 3
      # @halt = true
    end
  end

  def run
    while !halt do
      op, _ = get_arg
      op ||= 0
      step(op)
    end
  end

  def parse_program(input)
    # vax little-endian 16-bit
    @program = input.unpack('v*')
  end
end
