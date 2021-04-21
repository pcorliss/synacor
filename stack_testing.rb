# Run the following beforehand
# export RUBY_THREAD_VM_STACK_SIZE=1000000000

@cache = {}
@registers = []
@registers[7] = 3

def call_6027_memo(a, b)
  key = [a, b, @registers[7]]
  return @cache[key] if @cache[key]

  if a == 0
    a = (b + 1) % 32768
    @cache[key] = [a,b]
    return @cache[key]
  end

  if b == 0
    a = (a - 1) % 32768
    b = @registers[7]
    @cache[key] = call_6027_memo(a, b)
    return @cache[key]
  end

  tmp = a
  b = (b - 1) % 32768
  b, _ = call_6027_memo(a, b)
  a = (tmp - 1) % 32768
  @cache[key] = call_6027_memo(a, b)
  return @cache[key]
end

require 'parallel'

Parallel.each((0..32767)) do |i|
  @registers[7] = i
  @cache = {}
  a, b = call_6027_memo(4, 1)
  puts "R7: #{i} [4, 1] - #{[a, b]} - #{@cache.count}"
  if a == 6
    puts "Found working #{i} !!!!!!!!!"
    return
  end
end

# No scope pollution that I can see
# R7: 57 [4, 1] - [4597, 4596] - 101358
# R7: 58 [4, 1] - [19978, 19977] - 129658
# R7: 59 [4, 1] - [9995, 9994] - 101914
# R7: 60 [4, 1] - [17762, 17761] - 123044
# R7: 61 [4, 1] - [26857, 26856] - 124886
# R7: 62 [4, 1] - [62, 61] - 129026
# R7: 63 [4, 1] - [4159, 4158] - 73858
# R7: 64 [4, 1] - [23170, 23169] - 112892
# R7: 65 [4, 1] - [28733, 28732] - 126110
# R7: 66 [4, 1] - [18674, 18673] - 102256
# R7: 67 [4, 1] - [13203, 13202] - 108330
# R7: 68 [4, 1] - [2770, 2769] - 110664
# R7: 69 [4, 1] - [28017, 28016] - 121574
# R7: 70 [4, 1] - [1990, 1989] - 103896
# (57..70).each do |i|
#   @registers[7] = i
#   @cache = {}
#   a, b = call_6027_memo(4, 1)
#   puts "R7: #{i} [4, 1] - #{[a, b]} - #{@cache.count}"
#   if a == 6 || b == 6
#     puts "Found working #{i}"
#     break
#   end
# end
# ➜  synacor git:(main) ✗ export RUBY_THREAD_VM_STACK_SIZE=1000000000
# ➜  synacor git:(main) ✗ time ruby stack_testing.rb
# R7: 57 [4, 1] - [4597, 4596] - 101358
# R7: 58 [4, 1] - [19978, 19977] - 129658
# R7: 59 [4, 1] - [9995, 9994] - 101914
# R7: 60 [4, 1] - [17762, 17761] - 123044
# R7: 61 [4, 1] - [26857, 26856] - 124886
# R7: 62 [4, 1] - [62, 61] - 129026
# R7: 63 [4, 1] - [4159, 4158] - 73858
# R7: 64 [4, 1] - [23170, 23169] - 112892
# R7: 65 [4, 1] - [28733, 28732] - 126110
# R7: 66 [4, 1] - [18674, 18673] - 102256
# R7: 67 [4, 1] - [13203, 13202] - 108330
# R7: 68 [4, 1] - [2770, 2769] - 110664
# R7: 69 [4, 1] - [28017, 28016] - 121574
# R7: 70 [4, 1] - [1990, 1989] - 103896
# ruby stack_testing.rb  16.61s user 0.06s system 79% cpu 21.043 total


# 32767.times do |i|
#   @registers[7] = i
#   @cache = {}
#   a, b = call_6027_memo(4, 1)
#   puts "R7: #{i} [4, 1] - #{[a, b]} - #{@cache.count}"
#   if a == 6 || b == 6
#     puts "Found working #{i}"
#     break
#   end
# end

# def call_6027(a, b)
#   if a == 0
#     a = (b + 1) % 32768
#     return [a,b]
#   end
#
#   if b == 0
#     a = (a - 1) % 32768
#     b = @registers[7]
#     return call_6027(a, b)
#   end
#
#   tmp = a
#   b = (b - 1) % 32768
#   b, _ = call_6027(a, b)
#   a = (tmp - 1) % 32768
#   return call_6027(a, b)
# end

# require 'benchmark'
#
# b = Benchmark.measure do
#   4.times do |i|
#     @registers[7] = i
#     @cache = {}
#     a, b = call_6027_memo(4, 1)
#     puts "R7: #{i} [4, 1] - #{[a, b]} - #{@cache.count}"
#   end
# end
# puts b
#
# b = Benchmark.measure do
#   4.times do |i|
#     @registers[7] = i
#     @cache = {}
#     a, b = call_6027(4, 1)
#     puts "R7: #{i} [4, 1] - #{[a, b]} - #{@cache.count}"
#   end
# end
# puts b

