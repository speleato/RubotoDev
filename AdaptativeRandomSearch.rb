
require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :Button, :LinearLayout, :TextView

$activity.start_ruboto_activity "$sample_activity" do
  setTitle 'Adaptative Random Search'

  
  
  def on_create(bundle)
    self.content_view =
        linear_layout(:orientation => :vertical) do
          button :text => 'Manual de ayuda', :width => :wrap_content, :id => 41,
                    :on_click_listener => @ManualBusqueda
		  button :text => 'Ejecutar', :width => :wrap_content, :id => 42,
                    :on_click_listener => @Ejecutar
		@text_view = text_view :text => '', :id => 43
        end
  end
  
  
  
  @ManualBusqueda = proc do |view|
      @text_view.text = 'Algoritmo perteneciente a la familia de algoritmos de búsqueda estocásticos, consistentes en búsquedas directas de elementos.
						 El algoritmo de adaptación de búsqueda aleatorio fue diseñado para hacer frente a las limitaciones
						 del tamaño de paso fijo en el algoritmo de búsqueda aleatoria localizada. La clave de este algoritmo consiste en establecer el tamaño de salto
						 correcto para escapar de los óptimos locales. En cada iteracion tomará un salto de mayor tamaño y si el resultado de este salto ofrece una mejor
						 solución que el óptimo local tomará esa ruta. En caso de no encontrar un óptimo mejor, los saltos se irán acortando.
						 Parametros del algoritmo ejemplo:
						 -->tamaño del problema: 2
						 -->espacio de búsqueda: [-5,5]
						 -->maximo numero de iteraciones: 1000
						 -->Tamaño de salto pequeño inicial: 3
						 -->Tamaño de salto grande inicial: 10
						 -->valor de inicio:0.05
						 Recomendaciones
						 1/ En caso de empate entre dos soluciones candidatas, se tomará como mejora la nueva solución frente a la antigua
						 2/ El algoritmo puede adaptarse para buscar soluciones solo en una direccion (ej: solo hacia valores mayores que el actual)'
	  
  end
  
@Ejecutar = proc do |view|
	problem_size = 2
	bounds = Array.new(problem_size) {|i| [-5, +5]}
	max_iter = 1000
	s_factor = 1.3
	l_factor = 3.0
	iter_mult = 10
	max_no_impr = 30
	init_factor = 0.05
	best = search(max_iter, bounds, init_factor, s_factor, l_factor,iter_mult, max_no_impr)
	@text_view.text = "Done. Best Solution: c=#{best[:cost]}, v=#{best[:vector].inspect}"
end

def objective_function(vector)
	return vector.inject(0) {|sum, x| sum + (x ** 2.0)}
end

def rand_in_bounds(min, max)
 return min + ((max-min) * rand())
end

def random_vector(minmax)
	return Array.new(minmax.size) do |i|
	rand_in_bounds(minmax[i][0], minmax[i][1])
	end
end

def take_step(minmax, current, step_size)
	position = Array.new(current.size)
	position.size.times do |i|
	min = [minmax[i][0], current[i]-step_size].max
	max = [minmax[i][1], current[i]+step_size].min
	position[i] = rand_in_bounds(min, max)
	end
	return position
end

def large_step_size(iter, step_size, s_factor, l_factor, iter_mult)
	return step_size * l_factor if iter>0 and iter.modulo(iter_mult) == 0
	return step_size * s_factor
end

def take_steps(bounds, current, step_size, big_stepsize)
	step, big_step = {}, {}
	step[:vector] = take_step(bounds, current[:vector], step_size)
	step[:cost] = objective_function(step[:vector])
	big_step[:vector] = take_step(bounds,current[:vector],big_stepsize)
	big_step[:cost] = objective_function(big_step[:vector])
	return step, big_step
end

def search(max_iter, bounds, init_factor, s_factor, l_factor, iter_mult,max_no_impr)
	step_size = (bounds[0][1]-bounds[0][0]) * init_factor
	current, count = {}, 0
	current[:vector] = random_vector(bounds)
	current[:cost] = objective_function(current[:vector])
	max_iter.times do |iter|
	big_stepsize = large_step_size(iter, step_size, s_factor, l_factor,iter_mult)
	step, big_step = take_steps(bounds, current, step_size, big_stepsize)
	if step[:cost] <= current[:cost] or big_step[:cost] <= current[:cost]
		if big_step[:cost] <= step[:cost]
		step_size, current = big_stepsize, big_step
		else
		current = step
		end
		count = 0
		puts " > iteration #{(iter+1)}, best=#{current[:cost]}"
	else
		count += 1
		count, stepSize = 0, (step_size/s_factor) if count >= max_no_impr
	end
	
	end
	return current
end

#if __FILE__ == $0
# problem configuration
#problem_size = 2
#bounds = Array.new(problem_size) {|i| [-5, +5]}
# algorithm configuration
#max_iter = 1000
#init_factor = 0.05
#s_factor = 1.3
#l_factor = 3.0
#iter_mult = 10
#max_no_impr = 30
## execute the algorithm
#best = search(max_iter, bounds, init_factor, s_factor, l_factor,
#iter_mult, max_no_impr)
#puts "Done. Best Solution: c=#{best[:cost]}, v=#{best[:vector].inspect}"
end