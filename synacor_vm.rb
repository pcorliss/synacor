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
    @current = []
    @log = []
    @counter = 0
  end

  OP_LOOKUP = %w(
    halt
    set
    push
    pop
    eq
    gt
    jmp
    jt
    jf
    add
    mult
    mod
    and
    or
    not
    rmem
    wmem
    call
    ret
    out
    in
    noop
  )

  ARG_LOOKUP = [
    0,
    2,
    1,
    1,
    3,
    3,
    1,
    2,
    2,
    3,
    3,
    3,
    3,
    3,
    2,
    2,
    2,
    1,
    0,
    1,
    1,
    0,
  ]

  def get_arg
    a = @program[@pos]
    a_val = a && a >= 32768 ? @registers[a - 32768] : a
    if @current.empty?
      @current.push(@pos)
      @current.push(OP_LOOKUP[a])
    end
    # else
    #   @current.push(a)
    #   @current.push(a_val) if a >= 32768
    # end
    @pos += 1
    [a, a_val]
  end

  def step(op)
    if @pos == 5490
      @registers[0] = 3
      @registers[1] = 1
    end

    if @pos == 5492
      puts "Registers: #{@registers}"
    end

    if @pos == 6028
      cnt = @stack.count - 12
      @log.push(['*', '*'*cnt, @registers[0], @registers[1]])
    end

    case op
    when 0 # halt
      @halt = true
    when 1 # set
      a, _ = get_arg
      b, b_val = get_arg
      @current.concat ["r#{a - 32768}", b_val, '-', a, b]
      @registers[a - 32768] = b_val
    when 2 # push
      a, a_val = get_arg
      @current.concat [a_val, '-', a]
      @stack.push(a_val)
    when 3 # pop
      a, _ = get_arg
      raise "Stack Empty!" if @stack.empty?
      @registers[a - 32768] = @stack.pop
      @current.concat ["r#{a - 32768}", @registers[a - 32768], '-', a]
    when 4 # eq
      a, _ = get_arg
      b, b_val = get_arg
      c, c_val = get_arg
      @registers[a - 32768] = b_val == c_val ? 1 : 0
      @current.concat ["r#{a - 32768}", b_val, c_val, '-', @registers[a - 32768], '-', a, b, c]
    when 5 # gt
      a, _ = get_arg
      b, b_val = get_arg
      c, c_val = get_arg
      @registers[a - 32768] = b_val > c_val ? 1 : 0
      @current.concat ["r#{a - 32768}", b_val, c_val, '-', @registers[a - 32768], '-', a, b, c]
    when 6 # jmp
      a, a_val = get_arg
      @current.concat [a_val, '-', a]
      @pos = a_val
    when 7 # jt
      a, a_val = get_arg
      b, b_val = get_arg
      @current.concat [a_val, b_val, '-', !a_val.zero?, '-', a, b]
      @pos = b_val if !a_val.zero?
    when 8 # jf
      a, a_val = get_arg
      b, b_val = get_arg
      @current.concat [a_val, b_val, '-', a_val.zero?, '-', a, b]
      @pos = b_val if a_val.zero?
    when 9 # add
      a, _ = get_arg
      b, b_val = get_arg
      c, c_val = get_arg
      @registers[a - 32768] = (b_val + c_val) % 32768
      @current.concat ["r#{a - 32768}", b_val, c_val, '-', @registers[a - 32768], '-', a, b, c]
    when 10 # mult
      a, _ = get_arg
      b, b_val = get_arg
      c, c_val = get_arg
      @registers[a - 32768] = (b_val * c_val) % 32768
      @current.concat ["r#{a - 32768}", b_val, c_val, '-', @registers[a - 32768], '-', a, b, c]
    when 11 # mod
      a, _ = get_arg
      b, b_val = get_arg
      c, c_val = get_arg
      @registers[a - 32768] = b_val % c_val
      @current.concat ["r#{a - 32768}", b_val, c_val, '-', @registers[a - 32768], '-', a, b, c]
    when 12 # and
      a, _ = get_arg
      b, b_val = get_arg
      c, c_val = get_arg
      @registers[a - 32768] = b_val & c_val
      @current.concat ["r#{a - 32768}", b_val, c_val, '-', @registers[a - 32768], '-', a, b, c]
    when 13 # or
      a, _ = get_arg
      b, b_val = get_arg
      c, c_val = get_arg
      @registers[a - 32768] = b_val | c_val
      @current.concat ["r#{a - 32768}", b_val, c_val, '-', @registers[a - 32768], '-', a, b, c]
    when 14 # not - 15-bit inverse
      a, _ = get_arg
      b, b_val = get_arg
      val = 0
      15.times do |n|
        val += 2**n if b_val[n] == 0
      end
      @registers[a - 32768] = val
      @current.concat ["r#{a - 32768}", b_val, '-', @registers[a - 32768], '-', a, b]
    when 15 # rmem
      a, _ = get_arg
      b, b_val = get_arg
      @registers[a - 32768] = @program[b_val]
      @current.concat ["r#{a - 32768}", b_val, '-', @registers[a - 32768], '-', a, b]
    when 16 # wmem
      a, a_val = get_arg
      b, b_val = get_arg
      # @wmem.add(a_val)
      # puts "Mem: #{a_val} = #{b_val}" if @debug
      @program[a_val] = b_val
      @current.concat [a_val, b_val, '-', a, b]
    when 17 # call
      _, a_val = get_arg
      @current.concat [a_val, '-', @pos, '-', a]
      @stack.push(@pos)
      @pos = a_val
    when 18 # ret
      if @stack.empty?
        @halt = true
      else
        @pos = @stack.pop
        @current.concat [@pos]
      end
    when 19 # out
      a, a_val = get_arg
      @current.concat [a_val.chr, '-', a]
      print a_val.chr
    when 20 # in
      # puts "Prog: #{@program[@pos...(@pos+10)]}"
      a, _ = get_arg
      if @stdin_buffer.empty?
        # puts "Regst: #{@registers}" if @debug
        # puts "Stack: #{@stack}" if @debug
        # puts "Posit: #{@pos}" if @debug
        puts "Loc: #{@program[2733]}" if @debug
        puts "Orb: #{@program[3952]}" if @debug
        str = STDIN.gets()
        str = cheat if str == "cheat\n"
        str = vault if str == "goto vault\n"
        str = solve_coins if str == "solve_coins\n"
        str = solve_grid if str == "solve_grid\n"

        if str == "save\n"
          @backup = [@pos, @stack.clone, @registers.clone, @program.clone]
          str = "\n"
        end

        if str == "restore\n"
          @pos, @stack, @registers, @program = @backup
          str = "\n"
        end

        if str.start_with? 'set '
          _, n = str.split(' ')
          @registers[7] = n.to_i
        end

        if str == "registers\n"
          puts @registers.inspect
        end

        if str == "export\n"
          str = "use teleporter\n"
          @log = []
          @export = true
          @counter = 1_000_000
          @registers[7] = 3
        end

        if str == "reprogram\n"
          reprogram_teleporter
          str = "use teleporter\n"
        end

        if str == "finish\n"
          @counter = 0
          str = "\n"
        end

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
    @log.push(@current) if @export
    @current = []
    @counter -= 1 if @export
  end

  def mem
    mem = {}
    @wmem.each do |m|
      mem[m] = @program[m]
    end
    mem
  end

  def reprogram_teleporter
    @program[5489] = 1
    @program[5490] = 32768
    @program[5491] = 6
    @program[5492] = 1
    @program[5493] = 32769
    @program[5494] = 1
    @registers[7] = 25734
  end

  def cheat
    @debug = true
    record
    "take tablet\nuse tablet\ndoorway\nnorth\nnorth\nbridge\ncontinue\ndown\neast\ntake empty lantern\nwest\nwest\npassage\nladder\nwest\nsouth\nnorth\ntake can\nuse can\nwest\nuse lantern\nladder\ndarkness\ncontinue\nwest\nwest\nwest\nwest\nnorth\ntake red coin\nnorth\nwest\ntake blue coin\nup\ntake shiny coin\ndown\neast\neast\ntake concave coin\ndown\ntake corroded coin\nup\nwest\nuse blue coin\nuse red coin\nuse shiny coin\nuse concave coin\nuse corroded coin\nnorth\ntake teleporter\nuse teleporter\ntake business card\ntake strange book\n"
  end

  def vault
    "north\nnorth\nnorth\nnorth\nnorth\nnorth\nnorth\neast\ntake journal\nwest\nnorth\nnorth\n"
  end

  def solve_grid
    ["take orb", "north", "east", "east", "north", "west", "south", "east", "east", "west", "north", "north", "east", "vault", "take mirror", "use mirror"].join("\n") + "\n"
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
      if @export && @counter <= 0
        @halt = true
        File.open('export.log', 'w') do |fh|
          @log.each do |l|
            pos, *rest = l
            fh.puts"#{pos}: #{rest.join(' ')}"
          end
        end

        # positions = Set.new @log.map(&:first).sort
        # #
        # # # binding.pry
        # #
        # File.open('program.inst', 'w') do |fh|
        #   i = 0
        #   while i < @program.length do
        #     if positions.include? i
        #       op_code = @program[i]
        #       fh.print "#{i}: #{OP_LOOKUP[op_code]} "
        #       args = []
        #       ARG_LOOKUP[op_code].times do |j|
        #         i += 1
        #         args << @program[i]
        #       end
        #       fh.print args.join(' ')
        #       fh.print "\n"
        #     else
        #       fh.puts "#{i}: #{@program[i]}"
        #     end
        #     i += 1
        #   end
        # end
      end
    end
    puts @recorded if @recording
  end

  def parse_program(input)
    # vax little-endian 16-bit
    @program = input.unpack('v*')
  end
end
