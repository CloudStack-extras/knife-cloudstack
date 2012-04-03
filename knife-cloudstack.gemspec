Gem::Specification.new do |s|
  s.name = %q{knife-cloudstack}
  s.version = "0.0.12"
  s.date = %q{2012-04-02}
  s.authors = ['Ryan Holmes', 'KC Braunschweig', 'David Hudson', 'Julian Cardona']
  s.email = ['rholmes@edmunds.com', 'kbraunschweig@edmunds.com', 'dhudson@edmunds.com', 'jcardona@edmunds.com']
  s.summary = %q{A knife plugin for the CloudStack API}
  s.homepage = %q{http://www.edmunds.com/}
  s.description = %q{A Knife plugin to create, list and manage CloudStack servers}

  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "CHANGES.rdoc", "LICENSE" ]

  s.add_dependency "chef", ">= 0.10.0"
  s.require_path = 'lib'
  s.files = ["CHANGES.rdoc","README.rdoc", "LICENSE"] + Dir.glob("lib/**/*")
end
