require_library_or_gem 'Fixjour'

Fixjour do
  define_builder(User) do |klass, overrides|
    overrides.process(:owner) do |owner|
      overrides[:name] = owner.to_s
    end
    klass.new(:name => "" )
  end

  define_builder(Project) do |klass, overrides|
    overrides.process(:owner) do |owner|
      overrides[:name] = "#{owner.name}'s project!"
      overrides[:user_id] = owner.id
    end
  klass.new(:name => "", :user_id => nil)
  end

  define_builder(Feed) do |klass, overrides|
    overrides.process(:feedable) do |feedable|
      overrides[:name] = "#{feedable.name}'s feed!"
      overrides[:feedable_id] = feedable.id
      overrides[:feedable_type] =  feedable.class.to_s
    end

    klass.new(:name => "", :feedable_type=> nil, :feedable_id=> nil)
  end

  define_builder(Discussion) do |klass, overrides|
    overrides.process(:owner) do |owner|
      overrides[:name] = "#{owner.name}'s project!"
      overrides[:user_id] = owner.id
    end

    overrides.process(:discussible) do |discussible|
      overrides[:discussible_type] = discussible.class.to_s
      overrides[:discussible_id] = discussible.id
    end

    klass.new(:name => "", :user_id => nil, :discussible_id => nil, :discussible_type => nil )
  end
end

include Fixjour