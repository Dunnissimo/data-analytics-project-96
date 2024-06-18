with tab as (
select distinct
    s.visitor_id,
    date_trunc('day', visit_date) as visit_date,
    source,
    medium,
    campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id
from sessions s
left join leads l
    on l.visitor_id = s.visitor_id
),

vk_ya as (
    select
        ad_id,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content,
        date_trunc('day', campaign_date) as campaign_date,
        daily_spent
    from vk_ads

    union

    select
        ad_id,
        utm_source,
        utm_medium,
        utm_campaign,
        utm_content,
        date_trunc('day', campaign_date) as campaign_date,
        daily_spent
    from ya_ads
),

tab2 as (
select
    visitor_id,
    visit_date,
    utm_source,
    utm_medium,
    utm_campaign,
    lead_id,
    created_at,
    amount,
    closing_reason,
    status_id,
    daily_spent,
    row_number() over (partition by visitor_id order by visit_date desc) as rn
from tab t
left join vk_ya v
on
    t.source = v.utm_source
    and t.medium = v.utm_medium
    and t.campaign = v.utm_campaign
    and t.visit_date = v.campaign_date
where utm_medium in ('cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social')
order by
amount desc nulls last, visit_date asc, utm_source asc, utm_medium asc, utm_campaign asc
),

tab3 as (
select *
from tab2
where rn = 1
)

select
	date_trunc('day', visit_date) as visit_date,
	utm_source,
    utm_medium,
    utm_campaign,
    count(visitor_id) as visitors_count,
    sum(daily_spent) total_cost,
    count(lead_id) as leads_count,
    count(
    	case
    	when
    	closing_reason = 'Успешно реализовано' or status_id = '142'
    	then 'one'
    	end
    	) as purchases_count,
    sum(case when status_id = '142' then amount end) as revenue
from tab3
group by 1, 2, 3, 4
order by revenue desc nulls last, visit_date, visitors_count desc, utm_source, utm_medium, utm_campaign
limit 15;
