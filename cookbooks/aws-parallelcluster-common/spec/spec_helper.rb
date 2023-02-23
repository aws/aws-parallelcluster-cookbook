require 'chefspec'

module ChefSpec
  class Runner
    # Allows to converge a dynamic code block
    # For instance, it can be used to invoke actions on resources
    def converge_dsl(*recipes, &block)
      cookbook_name = 'any'
      recipe_name = 'any'
      converge(*recipes) do
        recipe = Chef::Recipe.new(cookbook_name, recipe_name, @run_context)
        recipe.instance_eval(&block)
      end
    end
  end
end
