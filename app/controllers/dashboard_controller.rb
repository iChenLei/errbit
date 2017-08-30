class DashboardController < ApplicationController

  #show the current_user's ticket
  def index
    
  end

#candition  query without time range  
  def user_query_no_time
    user_id = params[:userid]
    condition = params[:resolved] 

    startDate = params[:startdate] ? DateTime.parse(params[:startdate]) : DateTime.parse("1977-01-01")
    endDate = params[:enddate] ? DateTime.parse(params[:enddate]) : DateTime.now

    str = request.original_url
    page_flag = str.rindex(/page=/) ? str.rindex(/page=/)-1 : str.length;
    @url = str[0,page_flag]
    @current_page = params[:page] ? params[:page].to_i : 1
    @page_count = Problem.where(resolved: condition,assignee: user_id).all.count/20+1;
    @start = @current_page%10 == 0 ? @current_page : (@current_page/10)*10+1
    @end = @start+9 > @page_count ? @page_count : @start+9

    @infos = []
    @users = User.all.to_a
    # page = params[:page].to_i || 0
    @errors = Problem.where(resolved: condition,assignee: user_id,\
                            :last_notice_at.gt => startDate,\
                            :last_notice_at.lt => endDate).all.order_by(last_notice_at: :desc).skip((@current_page-1)*20).limit(20).to_a
    @errors.each do |error|
          @infos.push problems: error,user: User.where(_id: "#{error.assignee}").first
    end
    # puts @infos    
    render 'dashboard/test'
  end

#candition query with time
  def user_query_time
    startdate = params[:startdate].to_s
    enddate = params[:enddate].to_s
    @infos = Problem.where(:last_notice_at.lt => DateTime.parse(enddate),\
                  :last_notice_at.gt => DateTime.parse(startdate)).all.to_a
    render json: @infos
  end

#dashboard show function
  def showall
    @infos = []
    @user = current_user
    @resolvederrors = Problem.where(resolved: true).all.count
    @unresolvederrors = Problem.where(resolved: false).all.count
    @unassignederrors = Problem.any_of({assignee: :nil,resolved: false},{assignee: :none,resolved: false}).all.count
    users = User.all.to_a
    users.each do |user|
      @infos.push user: user,problems: Problem.where(assignee: user._id,resolved: false).order_by(last_notice_at: :desc).limit(15).to_a,\
                  resolved_count: Problem.where(assignee: user._id,resolved: true).all.count,\
                  unresolved_count: Problem.where(assignee: user._id,resolved: false).all.count
    end
    # puts @infos.to_s
    render 'dashboard/count' ,:infos => @infos,:res => @resolvederrors,\
                  :urs => @unresolvederrors,:uas => @unassignederrors
  end


#all query function
  def all
    @condition = params[:fliter]    

    str = request.original_url
    page_flag = str.rindex(/page=/) ? str.rindex(/page=/)-1 : str.length;
    @url = str[0,page_flag]
    @current_page = params[:page] ? params[:page].to_i : 1
    @page_count = all_query(@condition).all.count/20+1;
    @start = @current_page%10 == 0 ? @current_page : (@current_page/10)*10+1
    @end = @start+9 > @page_count ? @page_count : @start+9


    @infos = []
    @users = User.all.to_a
    # page = params[:page].to_i || 0
    @errors = all_query(@condition).all.order_by(last_notice_at: :desc).skip((@current_page-1)*20).limit(20).to_a
    @errors.each do |error|
          @infos.push problems: error,user: User.where(_id: "#{error.assignee}").first
    end
    # puts @infos    
    render 'dashboard/test'
  end

#pagination test
  def page
    str = request.original_url
    page_flag = str.rindex(/page=/) ? str.rindex(/page=/)-1 : str.length;
    @url = str[0,page_flag]
    p params[:cj]
    @current_page = params[:page] ? params[:page].to_i : 1
    @page_count = params[:pagecount].to_i
    @start = @current_page%10 == 0 ? @current_page : (@current_page/10)*10+1
    @end = @start+9 > @page_count ? @page_count : @start+9
    render 'dashboard/page'
  end

#index function  
  def query
    # @user = current_user
    @users = User.all.to_a
    render 'dashboard/index'
  end

  def assign 
    # @problem_id = params[:problem_id]
    # @assignee = params[:id]
    # problems = Problem.where(:_id => @problem_id).update(assignee: @assignee.to_s)
    # redirect 'dashboard/index'

    p_id = params[:p_id]
    u_id = params[:u_id]

    Problem.where(_id: p_id).update(assignee: u_id);

    redirect_to :controller => 'dashboard',:action => 'all'
  end


#protected function
protected
  def all_query(condition)
    case condition
      when "allresolved"
        Problem.where(resolved: true)
      when "allunresolved"  
        Problem.where(resolved: false)
      when "allunassigned"  
        Problem.any_of({assignee: :nil,resolved: false},{assignee: :none,resolved: false})
      else
        Problem.any_of({assignee: :nil,resolved: false},{assignee: :none,resolved: false})  
    end
  end        
end