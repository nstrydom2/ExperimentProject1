function [winLoss,profit] = validateModel(model,data)
    %VALIDATEMODEL Summary of this function goes here
    %   Detailed explanation goes here
    [positions, info] = classify(model, data);
    [wins, profit] = arrayfun(@(x, y) validateDay(x, y), positions, data);

    winLoss = sum(wins);
    profit = sum(profit);
end


function [win, profit] = validateDay(position, dayData)
    prevPrice = dayData.prevPrice;
    todayPrice = dayDate.todayPrice;

    if position == "LONG"
        profit = todayPrice - prevPrice;

        if profit > 0.0
            win = true;
        else
            win = false;
        end
        
    elseif position == "SHORT"
        profit = prevPrice - todayPrice;

        if profit > 0.0
            win = true;
        else
            win = false;
        end
    end
end