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
