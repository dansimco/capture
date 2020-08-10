local helpers = {}


-- Table Reducer
helpers.reduce = function (list, fn) 
    local acc
    for k, v in ipairs(list) do
        if 1 == k then
            acc = v
        else
            acc = fn(acc, v)
        end 
    end 
    return acc 
end


-- Looping Incrementor 
function helpers.inc(n,max,min)
  if max and n > max then n = min end
  n = n + 1
  return n
end


-- Averager (meaner?)
function helpers.averager(steps) 
  local avg = {}
  local values = {}
  local step = 1
  function avg:push(n)
    values[step] = n
    step = helpers.inc(step, steps, 1)
    avg.value = helpers.reduce(values, function(a, b) return a+b end) / steps
  end
  return avg
end


return helpers