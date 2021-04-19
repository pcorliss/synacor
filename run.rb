require_relative './synacor_vm.rb'

vm = SynacorVm.new
vm.parse_program(File.read('challenge.bin'))
vm.run
