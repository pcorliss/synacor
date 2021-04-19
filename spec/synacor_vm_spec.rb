require_relative '../synacor_vm.rb'

describe SynacorVm do
  let(:input) { "9,32768,32769,4,19,32768" }
  let(:vm) { SynacorVm.new(input) }

  describe '#new' do
    it "inits eight registers" do
      expect(vm.registers.count).to eq(8)
      expect(vm.registers[0]).to eq(0)
    end

    it "inits a program" do
      expect(vm.program.count).to eq(6)
      expect(vm.program[0]).to eq(9)
    end

    it "inits a position" do
      expect(vm.pos).to eq(0)
    end

    it "inits an empty stack" do
      expect(vm.stack.count).to eq(0)
    end
  end

  describe '#run' do
    it 'runs until halt is encountered' do
      expect { vm.run }.to output.to_stdout
      expect(vm.halt).to be_truthy
    end

    context "validation" do
      it 'handles the basic input' do
        vm.registers[1] = 60
        expect { vm.run }.to output('@').to_stdout
        expect(vm.registers[0]).to eq(64)
      end
    end
  end

  describe '#get_arg' do
    it 'gets an argument from the program' do
      expect(vm.get_arg).to eq([9, 9])
    end

    it 'returns the original as well as the val' do
      vm.get_arg
      vm.registers[0] = 99
      expect(vm.get_arg).to eq([32768, 99])
    end

    it 'increments the pos counter' do
      vm.get_arg
      expect(vm.pos).to eq(1)
    end
  end

  describe '#step' do
    describe '#halt' do
      it 'sets halt to true' do
        expect(vm.halt).to be_falsey
        vm.step(0)
        expect(vm.halt).to be_truthy
      end
    end

    describe '#out' do
      it "writes ascii char to STDOUT" do
        vm.program.unshift(64)
        expect { vm.step(19) }.to output('@').to_stdout
      end
    end

    describe '#noop' do
      # xit "does nothing" do
      # end
    end

    describe '#add' do
      it "adds <b> and <c> and assigns to a" do
        vm.program.unshift(32768, 1, 2)
        vm.step(9)
        expect(vm.registers[0]).to eq(3)
      end

      it "performs math modulo 32768" do
        vm.program.unshift(32768, 32765, 32765)
        vm.step(9)
        expect(vm.registers[0]).to eq(32762)
      end

      it "reads from registers instead of using literals" do
        vm.registers[0] = 1
        vm.registers[1] = 2
        vm.program.unshift(32768, 32768, 32769)
        vm.step(9)
        expect(vm.registers[0]).to eq(3)
      end
    end

    describe '#mult' do
      it "adds <b> and <c> and assigns to a" do
        vm.program.unshift(32768, 2, 3)
        vm.step(10)
        expect(vm.registers[0]).to eq(6)
      end

      it "performs math modulo 32768" do
        vm.program.unshift(32768, 32765, 32765)
        vm.step(10)
        expect(vm.registers[0]).to eq(9)
      end
    end

    describe '#mod' do
      it "mods <b> by <c> and assigns to a" do
        vm.program.unshift(32768, 88, 7)
        vm.step(11)
        expect(vm.registers[0]).to eq(4)
      end
    end

    describe '#jmp' do
      it 'jumps to a specific position' do
        vm.program.unshift(88)
        vm.step(6)
        expect(vm.pos).to eq(88)
      end
    end

    describe '#jt' do
      it 'jumps to a specific position' do
        vm.program.unshift(77, 88)
        vm.step(7)
        expect(vm.pos).to eq(88)
      end

      it 'does nothing if a is zero' do
        vm.program.unshift(0, 88)
        vm.step(7)
        expect(vm.pos).to_not eq(88)
      end
    end

    describe '#jf' do
      it 'does nothing if a is not zero' do
        vm.program.unshift(77, 88)
        vm.step(8)
        expect(vm.pos).to_not eq(88)
      end

      it 'jumps if a is zero' do
        vm.program.unshift(0, 88)
        vm.step(8)
        expect(vm.pos).to eq(88)
      end
    end

    describe '#set' do
      it 'sets register a to the value of b' do
        vm.program.unshift(32768, 99)
        vm.step(1)
        expect(vm.registers[0]).to eq(99)
      end
    end

    describe '#eq' do
      it 'set <a> to 1 if <b> is equal to <c>' do
        vm.program.unshift(32768, 99, 99)
        vm.step(4)
        expect(vm.registers[0]).to eq(1)
      end

      it 'set <a> to 0 if <b> is not equal to <c>' do
        vm.program.unshift(32768, 99, 98)
        vm.step(4)
        expect(vm.registers[0]).to eq(0)
      end
    end

    describe '#gt' do
      it 'set <a> to 1 if <b> is greater than to <c>' do
        vm.program.unshift(32768, 100, 99)
        vm.step(5)
        expect(vm.registers[0]).to eq(1)
      end

      it 'set <a> to 0 if <b> is not greater than <c>' do
        vm.program.unshift(32768, 99, 99)
        vm.step(5)
        expect(vm.registers[0]).to eq(0)
      end
    end

    describe '#push' do
      it 'push <a> onto the stack' do
        vm.program.unshift(99)
        vm.step(2)
        expect(vm.stack).to eq([99])
      end
    end

    describe '#pop' do
      it 'remove the top element from the stack and write it into <a>' do
        vm.stack.push(99)
        vm.program.unshift(32768)
        vm.step(3)
        expect(vm.stack).to eq([])
        expect(vm.registers[0]).to eq(99)
      end

      it 'throws an err if the stack is empty' do
        vm.program.unshift(32768)
        expect { vm.step(3) }.to raise_error("Stack Empty!")
      end
    end

    describe '#and' do
      it 'stores into <a> the bitwise and of <b> and <c>' do
        vm.program.unshift(32768, 3, 11)
        vm.step(12)
        expect(vm.registers[0]).to eq(3)
      end
    end

    describe '#or' do
      it 'stores into <a> the bitwise and of <b> and <c>' do
        vm.program.unshift(32768, 56, 7)
        vm.step(13)
        expect(vm.registers[0]).to eq(63)
      end
    end

    describe '#not' do
      it 'stores 15-bit bitwise inverse of <b> in <a>' do
        vm.program.unshift(32768, 0)
        vm.step(14)
        expect(vm.registers[0]).to eq(32767)
      end
    end
  end

  describe "#parse_program" do
    it "each number is stored as a 16-bit little-endian pair (low byte, high byte)" do
      vm.parse_program(File.read('challenge.bin').slice(0,100))
      expect(vm.program.first(8)).to eq([21,21,19,87,19,101,19,108])
    end

    it "can parse the entire challenge file" do
      expect do
        vm.parse_program(File.read('challenge.bin'))
      end.to_not raise_error
    end
  end
end
