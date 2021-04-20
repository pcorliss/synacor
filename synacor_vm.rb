require 'pry'
require 'set'

class SynacorVm
  attr_reader :registers, :program, :halt, :pos, :stack, :recording, :recorded

  def initialize(input = '')
    @registers = 8.times.map { 0 }
    @program = input.split(',').map(&:to_i)
    @halt = false
    @pos = 0
    @stack = []
    @stdin_buffer = []
    @recording = false
    @recorded = ''
    @wmem = Set.new
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
      # @wmem.add(a_val)
      # puts "Mem: #{a_val} = #{b_val}" if @debug
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
      a, _ = get_arg
      if @stdin_buffer.empty?
        # puts "Regst: #{@registers}" if @debug
        # puts "Stack: #{@stack}" if @debug
        # puts "Posit: #{@pos}" if @debug
        puts "Memor: #{@program[2733]}" if @debug
        str = STDIN.gets()
        str = cheat if str == "cheat\n"
        str = solve_coins if str == "solve_coins\n"
        if str == "debug\n"
          str = "\n"
          binding.pry
        end
        @stdin_buffer = str.chars.map(&:ord)
        @recorded << str if @recording
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

  def mem
    mem = {}
    @wmem.each do |m|
      mem[m] = @program[m]
    end
    mem
  end

  def cheat
    @debug = true
    record
    "take tablet\nuse tablet\ndoorway\nnorth\nnorth\nbridge\ncontinue\ndown\neast\ntake empty lantern\nwest\nwest\npassage\nladder\nwest\nsouth\nnorth\ntake can\nuse can\nwest\nuse lantern\nladder\ndarkness\ncontinue\nwest\nwest\nwest\nwest\nnorth\ntake red coin\nnorth\nwest\ntake blue coin\nup\ntake shiny coin\ndown\neast\neast\ntake concave coin\ndown\ntake corroded coin\nup\nwest\nuse blue coin\nuse red coin\nuse shiny coin\nuse concave coin\nuse corroded coin\nnorth\ntake teleporter\nuse teleporter\n"
  end

  COINS = [
    "red coin",
    "corroded coin",
    "shiny coin",
    "concave coin",
    "blue coin",
  ]

  def solve_coins
    str = ''
    COINS.permutation.each do |perm|
      str << "use " + perm.join("\nuse ") + "\n"
      str << "take " + perm.join("\ntake ") + "\n"
    end
    str
  end

  def record
    @recording = true
  end

  def run
    while !halt do
      op, _ = get_arg
      op ||= 0
      step(op)
    end
    puts @recorded if @recording
  end

  def parse_program(input)
    # vax little-endian 16-bit
    @program = input.unpack('v*')
  end
end
