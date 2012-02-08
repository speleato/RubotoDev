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
	problem_size = 3
	bounds = Array.new(problem_size) {|i| [-5, +5]}
	max_iter = 100
	step_size = (bounds[0][1]-bounds[0][0])*0.005
	max_no_improv = 30
	ref_set_size = 10
	diverse_set_size = 20
	no_elite = 5
	best = search(bounds, max_iter, ref_set_size, diverse_set_size,max_no_improv, step_size, no_elite)
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

def local_search(best, bounds, max_no_improv, step_size)
	count = 0
	begin
	candidate = {:vector=>take_step(bounds, best[:vector], step_size)}
	candidate[:cost] = objective_function(candidate[:vector])
	count = (candidate[:cost] < best[:cost]) ? 0 : count+1
	best = candidate if candidate[:cost] < best[:cost]
	end until count >= max_no_improv
	return best
end

def construct_initial_set(bounds, set_size, max_no_improv, step_size)
	diverse_set = []
	begin
	cand = {:vector=>random_vector(bounds)}
	cand[:cost] = objective_function(cand[:vector])
	cand = local_search(cand, bounds, max_no_improv, step_size)
	diverse_set << cand if !diverse_set.any? {|x| x[:vector]==cand[:vector]}
	end until diverse_set.size == set_size
	return diverse_set
end

def euclidean_distance(c1, c2)
	sum = 0.0
	c1.each_index {|i| sum += (c1[i]-c2[i])**2.0}
	return Math.sqrt(sum)
end

def distance(v, set)
	return set.inject(0){|s,x| s + euclidean_distance(v, x[:vector])}
end

def diversify(diverse_set, num_elite, ref_set_size)
	diverse_set.sort!{|x,y| x[:cost] <=> y[:cost]}
	ref_set = Array.new(num_elite){|i| diverse_set[i]}
	remainder = diverse_set - ref_set
	remainder.each{|c| c[:dist] = distance(c[:vector], ref_set)}
	remainder.sort!{|x,y| y[:dist]<=>x[:dist]}
	ref_set = ref_set + remainder.first(ref_set_size-ref_set.size)
	return [ref_set, ref_set[0]]
end

def select_subsets(ref_set)
	additions = ref_set.select{|c| c[:new]}
	remainder = ref_set - additions
	remainder = additions if remainder.nil? or remainder.empty?
	subsets = []
	additions.each do |a|
	remainder.each{|r| subsets << [a,r] if a!=r && !subsets.include?([r,a])}
	end
	return subsets
end

def recombine(subset, minmax)
	a, b = subset
	d = rand(euclidean_distance(a[:vector], b[:vector]))/2.0
	children = []
	subset.each do |p|
	step = (rand<0.5) ? +d : -d
	child = {:vector=>Array.new(minmax.size)}
	child[:vector].each_index do |i|
	child[:vector][i] = p[:vector][i] + step
	child[:vector][i]=minmax[i][0] if child[:vector][i]<minmax[i][0]
	child[:vector][i]=minmax[i][1] if child[:vector][i]>minmax[i][1]
	end
	child[:cost] = objective_function(child[:vector])
	children << child
	end
	return children
end

def explore_subsets(bounds, ref_set, max_no_improv, step_size)
	was_change = false
	subsets = select_subsets(ref_set)
	ref_set.each{|c| c[:new] = false}
	subsets.each do |subset|
	candidates = recombine(subset, bounds)
	improved = Array.new(candidates.size) do |i|
	local_search(candidates[i], bounds, max_no_improv, step_size)
	end
	improved.each do |c|
		if !ref_set.any? {|x| x[:vector]==c[:vector]}
			c[:new] = true
			ref_set.sort!{|x,y| x[:cost] <=> y[:cost]}
			if c[:cost] < ref_set.last[:cost]
				ref_set.delete(ref_set.last)
				ref_set << c
				puts " >> added, cost=#{c[:cost]}"
				was_change = true
			end
		 end
	end
	end
	return was_change
end

def search(bounds, max_iter, ref_set_size, div_set_size, max_no_improv,
	step_size, max_elite)
	diverse_set = construct_initial_set(bounds, div_set_size, max_no_improv,step_size)
	ref_set, best = diversify(diverse_set, max_elite, ref_set_size)
	ref_set.each{|c| c[:new] = true}
	max_iter.times do |iter|
	was_change = explore_subsets(bounds, ref_set, max_no_improv, step_size)
	ref_set.sort!{|x,y| x[:cost] <=> y[:cost]}
	best = ref_set.first if ref_set.first[:cost] < best[:cost]
	puts " > iter=#{(iter+1)}, best=#{best[:cost]}"
	break if !was_change
	end
	return best
end

end