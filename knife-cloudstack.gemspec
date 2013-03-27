Gem::Specification.new do |s|
  s.name = %q{knife-cloudstack}
  s.version = "0.0.14"
  s.date = %q{2012-12-10}
  s.authors = ['Ryan Holmes', 'KC Braunschweig', 'John E. Vincent', 'Chirag Jog', 'Sander Botman', 'Frank Breedijk']
  s.email = ['rholmes@edmunds.com', 'kcbraunschweig@gmail.com', 'lusis.org+github.com@gmail.com', 'chirag.jog@me.com', 'sbotman@schubergphilis.com'. 'fbreedijk@schubergphilis.com' ]
  s.summary = %q{A knife plugin for the CloudStack API}
  s.homepage = %q{http://cloudstack.org/}
  s.description = %q{A Knife plugin to create, list and manage CloudStack servers and other objects}

  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "CHANGES.rdoc", "LICENSE" ]

  s.add_dependency "chef", ">= 0.10.0"
  s.add_dependency "knife-windows", ">= 0"
  s.require_path = 'lib'
  s.files = ["CHANGES.rdoc","README.rdoc", "LICENSE"] + Dir.glob("lib/**/*")
end
