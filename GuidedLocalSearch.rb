require 'ruboto/activity'
require 'ruboto/widget'
require 'ruboto/util/toast'

ruboto_import_widgets :Button, :LinearLayout, :TextView

$activity.start_ruboto_activity "$sample_activity" do
  setTitle 'Guided local search'

  
  
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
      @text_view.text = 'La estrategia de la búsqueda local guiada es penalizar las soluciones encontradas de tal forma que el algoritmo de búsqueda local pueda escapar de los óptimos
	  locales. Cuando el algortimo de búsqueda local definido se queda atascado en un óptimo local, se guardan sus características y se le penaliza, de tal forma que la búsqueda pueda seguir por otro camino
	  eluyendo así el quedarse atascado. Además la función de evaluación evita los entornos de las soluciones óptimas encontradas para poder buscar en entornos no explorados aun.
	  Parametros del algoritmo ejemplo
	  -->datos_iniciales: [[565,575],[25,185],[345,750],[945,685],[845,655],[880,660],[25,230],[525,1000],[580,1175],[650,1130],[1605,620],[1220,580],[1465,200],[1530,5],[845,680],[725,370],[145,665],[415,635],[510,875],[560,365],[300,465],[520,585],[480,415],[835,625],[975,580],[1215,245],[1320,315],[1250,400],[660,180],[410,250],[420,555],[575,665],[1150,1160],[700,580],[685,595],[685,610],[770,610],[795,645],[720,635],[760,650],[475,960],[95,260],[875,920],[700,500],[555,815],[830,485],[1170,65],[830,610],[605,625],[595,360],[1340,725],[1740,245]]
	  -->Máximo número de iteraciones:150
	  -->Máximo número de mejoras:20
	  -->Multiplicador: 0.3
	  -->local_search_optima = 12000.0
	  -->Función de valoración = Multiplicador * (local_search_optima/datos_iniciales.size.to_f)
	  Recomendaciones
	  1/ El algoritmo de busqueda guiada es independiente del heuristico embebido en el.
	  2/ Este algoritmo puede que necesite ser ejecutado miles de veces, teniendo que ejecutar una busqueda local en cada iteración, por lo que su costo puede dispararse facilmente.
	  3/ Este algoritmo fue diseñado para problemas de optimización discreta donde una solución se compone de caracteristicas independientes, como la optimización combinatoria'
end

@Ejecutar = proc do |view|
	berlin52 = [[565,575],[25,185],[345,750],[945,685],[845,655],[880,660],[25,230],[525,1000],[580,1175],[650,1130],[1605,620],[1220,580],[1465,200],[1530,5],[845,680],[725,370],[145,665],[415,635],[510,875],[560,365],[300,465],[520,585],[480,415],[835,625],[975,580],[1215,245],[1320,315],[1250,400],[660,180],[410,250],[420,555],[575,665],[1150,1160],[700,580],[685,595],[685,610],[770,610],[795,645],[720,635],[760,650],[475,960],[95,260],[875,920],[700,500],[555,815],[830,485],[1170,65],[830,610],[605,625],[595,360],[1340,725],[1740,245]]
	max_iterations = 150
	max_no_improv = 20
	alpha = 0.3
	local_search_optima = 12000.0
	lambda = alpha * (local_search_optima/berlin52.size.to_f)
	best = search(max_iterations, berlin52, max_no_improv, lambda)
	@text_view.text = "Done. Best Solution: c=#{best[:cost]}, v=#{best[:vector].inspect}"
end


def euc_2d(c1, c2)
	Math.sqrt((c1[0] - c2[0])**2.0 + (c1[1] - c2[1])**2.0).round
end
	
def random_permutation(cities)
	perm = Array.new(cities.size){|i| i}
	perm.each_index do |i|
	r = rand(perm.size-i) + i
	perm[r], perm[i] = perm[i], perm[r]
	end
	return perm
end

def stochastic_two_opt(permutation)
	perm = Array.new(permutation)
	c1, c2 = rand(perm.size), rand(perm.size)
	exclude = [c1]
	exclude << ((c1==0) ? perm.size-1 : c1-1)
	exclude << ((c1==perm.size-1) ? 0 : c1+1)
	c2 = rand(perm.size) while exclude.include?(c2)
	c1, c2 = c2, c1 if c2 < c1
	perm[c1...c2] = perm[c1...c2].reverse
	return perm
end

def augmented_cost(permutation, penalties, cities, lambda)
	distance, augmented = 0, 0
	permutation.each_with_index do |c1, i|
	c2 = (i==permutation.size-1) ? permutation[0] : permutation[i+1]
	c1, c2 = c2, c1 if c2 < c1
	d = euc_2d(cities[c1], cities[c2])
	distance += d
	augmented += d + (lambda * (penalties[c1][c2]))
	end
	return [distance, augmented]
end

def cost(cand, penalties, cities, lambda)
	cost, acost = augmented_cost(cand[:vector], penalties, cities, lambda)
	cand[:cost], cand[:aug_cost] = cost, acost
end

def local_search(current, cities, penalties, max_no_improv, lambda)
	cost(current, penalties, cities, lambda)
	count = 0
	begin
		candidate = {:vector=> stochastic_two_opt(current[:vector])}
		cost(candidate, penalties, cities, lambda)
		count = (candidate[:aug_cost] < current[:aug_cost]) ? 0 : count+1
		current = candidate if candidate[:aug_cost] < current[:aug_cost]
	end until count >= max_no_improv
	return current
end

def calculate_feature_utilities(penal, cities, permutation)
	utilities = Array.new(permutation.size,0)
	permutation.each_with_index do |c1, i|
	c2 = (i==permutation.size-1) ? permutation[0] : permutation[i+1]
	c1, c2 = c2, c1 if c2 < c1
	utilities[i] = euc_2d(cities[c1], cities[c2]) / (1.0 + penal[c1][c2])
	end
	return utilities
end

def update_penalties!(penalties, cities, permutation, utilities)
	max = utilities.max()
	permutation.each_with_index do |c1, i|
	c2 = (i==permutation.size-1) ? permutation[0] : permutation[i+1]
	c1, c2 = c2, c1 if c2 < c1
	penalties[c1][c2] += 1 if utilities[i] == max
	end
	return penalties
end

def search(max_iterations, cities, max_no_improv, lambda)
	current = {:vector=>random_permutation(cities)}
	best = nil
	penalties = Array.new(cities.size){ Array.new(cities.size, 0) }
	max_iterations.times do |iter|
	current=local_search(current, cities, penalties, max_no_improv, lambda)
	utilities=calculate_feature_utilities(penalties,cities,current[:vector])
	update_penalties!(penalties, cities, current[:vector], utilities)
	best = current if best.nil? or current[:cost] < best[:cost]
	puts " > iter=#{(iter+1)}, best=#{best[:cost]}, aug=#{best[:aug_cost]}"
	end
	return best
end

end