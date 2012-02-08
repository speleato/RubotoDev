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
      @text_view.text = 'Prueba a ver si sale el texto'
end

@Ejecutar = proc do |view|
	berlin52 = [[565,575],[25,185],[345,750],[945,685],[845,655],[880,660],[25,230],[525,1000],[580,1175],[650,1130],[1605,620],[1220,580],[1465,200],[1530,5],[845,680],[725,370],[145,665],[415,635],[510,875],[560,365],[300,465],[520,585],[480,415],[835,625],[975,580],[1215,245],[1320,315],[1250,400],[660,180],[410,250],[420,555],[575,665],[1150,1160],[700,580],[685,595],[685,610],[770,610],[795,645],[720,635],[760,650],[475,960],[95,260],[875,920],[700,500],[555,815],[830,485],[1170,65],[830,610],[605,625],[595,360],[1340,725],[1740,245]]
	max_iterations = 100
	max_no_improv = 50
	num_bits = 64
	max_iterations = 1000
	best = search(berlin52, max_iterations, max_no_improv)
	@text_view.text = "Done. Best Solution: c=#{best[:cost]}, v=#{best[:vector].inspect}"
end


def euc_2d(c1, c2)
	Math.sqrt((c1[0] - c2[0])**2.0 + (c1[1] - c2[1])**2.0).round
end

def cost(permutation, cities)
	distance =0
	permutation.each_with_index do |c1, i|
	c2 = (i==permutation.size-1) ? permutation[0] : permutation[i+1]
	distance += euc_2d(cities[c1], cities[c2])
	end
	return distance
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

def local_search(best, cities, max_no_improv)
	count = 0
	begin
	candidate = {:vector=>stochastic_two_opt(best[:vector])}
	candidate[:cost] = cost(candidate[:vector], cities)
	count = (candidate[:cost] < best[:cost]) ? 0 : count+1
	best = candidate if candidate[:cost] < best[:cost]
	end until count >= max_no_improv
	return best
end

def double_bridge_move(perm)
	pos1 = 1 + rand(perm.size / 4)
	pos2 = pos1 + 1 + rand(perm.size / 4)
	pos3 = pos2 + 1 + rand(perm.size / 4)
	p1 = perm[0...pos1] + perm[pos3..perm.size]
	p2 = perm[pos2...pos3] + perm[pos1...pos2]
	return p1 + p2
end

def perturbation(cities, best)
	candidate = {}
	candidate[:vector] = double_bridge_move(best[:vector])
	candidate[:cost] = cost(candidate[:vector], cities)
	return candidate
	end
	
def search(cities, max_iterations, max_no_improv)
	best = {}
	best[:vector] = random_permutation(cities)
	best[:cost] = cost(best[:vector], cities)
	best = local_search(best, cities, max_no_improv)
	max_iterations.times do |iter|
	candidate = perturbation(cities, best)
	candidate = local_search(candidate, cities, max_no_improv)
	best = candidate if candidate[:cost] < best[:cost]
	puts " > iteration #{(iter+1)}, best=#{best[:cost]}"
	end
	return best
end

end



